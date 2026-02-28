import Foundation
import AVFoundation

protocol SegmentRecorderServiceDelegate: AnyObject {
    func segmentRecorderService(_ service: SegmentRecorderService, didStartSegment record: Record)
    func segmentRecorderService(_ service: SegmentRecorderService, didFinishSegment record: Record)
    func segmentRecorderService(_ service: SegmentRecorderService, didUpdateMeteringLevel level: Float)
    func segmentRecorderServiceDidFail(_ service: SegmentRecorderService)
}

final class SegmentRecorderService: NSObject, AVAudioRecorderDelegate {
    struct Config {
        var segmentDuration: TimeInterval
        var quality: AVAudioQuality
        var maxSegmentSizeMB: Int

        var maxSegmentSizeBytes: Int64 {
            Int64(max(1, maxSegmentSizeMB)) * 1024 * 1024
        }
    }

    weak var delegate: SegmentRecorderServiceDelegate?

    private let storage: RecordingStorage
    private var recorder: AVAudioRecorder?
    private var rotationTimer: Timer?
    private var sizeTimer: Timer?
    private var meteringTimer: Timer?
    private var currentSegment: Record?

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    var config: Config {
        didSet {
            if isRecording {
                stop()
                start()
            }
        }
    }

    init(storage: RecordingStorage, config: Config) {
        self.storage = storage
        self.config = config
        super.init()
    }

    func start() {
        guard !isRecording else { return }
        startNewSegment()
    }

    func stop() {
        rotationTimer?.invalidate()
        rotationTimer = nil

        meteringTimer?.invalidate()
        meteringTimer = nil

        sizeTimer?.invalidate()
        sizeTimer = nil

        guard let recorder else { return }
        recorder.stop()
        finalizeCurrentSegment(success: true)
        self.recorder = nil
    }

    private func startNewSegment() {
        storage.createRecordsDirectoryIfNotExists()
        let segment = storage.createNewRecord(at: Date())

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: config.quality == .high ? 44100 : 22050,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: config.quality.rawValue,
            AVEncoderBitRateKey: config.quality == .high ? 128000 : 64000
        ]

        do {
            let url = storage.recordURL(for: segment.title)
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            guard recorder?.record() == true else {
                delegate?.segmentRecorderServiceDidFail(self)
                return
            }

            currentSegment = segment
            storage.indexSegmentStart(segment)
            delegate?.segmentRecorderService(self, didStartSegment: segment)
            startTimers()
        } catch {
            delegate?.segmentRecorderServiceDidFail(self)
        }
    }

    private func rotateSegment() {
        guard isRecording else { return }
        recorder?.stop()
        finalizeCurrentSegment(success: true)
        startNewSegment()
    }

    private func checkSegmentSizeAndRotateIfNeeded() {
        guard isRecording, let currentSegment else { return }
        let url = storage.recordURL(for: currentSegment.title)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        if fileSize >= config.maxSegmentSizeBytes {
            rotateSegment()
        }
    }

    private func startTimers() {
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: config.segmentDuration, repeats: true) { [weak self] _ in
            self?.rotateSegment()
        }

        sizeTimer?.invalidate()
        sizeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkSegmentSizeAndRotateIfNeeded()
        }

        meteringTimer?.invalidate()
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            let normalizedLevel = pow(10, level / 20)
            self.delegate?.segmentRecorderService(self, didUpdateMeteringLevel: normalizedLevel)
        }
    }

    private func finalizeCurrentSegment(success: Bool) {
        guard success, let segment = currentSegment else {
            currentSegment = nil
            return
        }

        let url = storage.recordURL(for: segment.title)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        let finishedSegment = Record(title: segment.title, date: segment.date, endDate: Date(), sizeBytes: fileSize)

        storage.indexSegmentEnd(fileName: finishedSegment.title, endAt: finishedSegment.endDate ?? Date(), sizeBytes: fileSize)
        delegate?.segmentRecorderService(self, didFinishSegment: finishedSegment)
        currentSegment = nil
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            delegate?.segmentRecorderServiceDidFail(self)
        }
    }
}
