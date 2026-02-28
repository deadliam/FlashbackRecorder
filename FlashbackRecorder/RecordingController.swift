import Foundation
import AVFoundation

protocol RecordingControllerDelegate: AnyObject {
    func recordingController(_ controller: RecordingController, didChangeStateTo state: RecordingController.State)
    func recordingController(_ controller: RecordingController, didUpdateMeteringLevel level: Float)
}

final class RecordingController: NSObject, AVAudioPlayerDelegate, SegmentRecorderServiceDelegate {
    weak var delegate: RecordingControllerDelegate?

    private let recordingSession = AVAudioSession.sharedInstance()
    private let storage = RecordingStorage()
    private var segmentRecorder: SegmentRecorderService!
    private var player: AVAudioPlayer?

    private var recDuration: TimeInterval = 300
    private var maxFiles = 50
    private var recordingQuality: AVAudioQuality = .high
    private var segmentSizeMB: Int = 10

    struct RecordingSettings {
        var duration: TimeInterval
        var quality: AVAudioQuality
        var maxRecordings: Int
        var segmentSizeMB: Int
    }

    var settings: RecordingSettings {
        get {
            RecordingSettings(
                duration: recDuration,
                quality: recordingQuality,
                maxRecordings: maxFiles,
                segmentSizeMB: segmentSizeMB
            )
        }
        set {
            recDuration = newValue.duration
            recordingQuality = newValue.quality
            maxFiles = newValue.maxRecordings
            segmentSizeMB = max(1, newValue.segmentSizeMB)
            segmentRecorder.config = SegmentRecorderService.Config(
                segmentDuration: recDuration,
                quality: recordingQuality,
                maxSegmentSizeMB: segmentSizeMB
            )
            storage.removeRecordsIfNeeded(maxCount: maxFiles)
        }
    }

    enum State {
        case initial
        case recording
        case readyToRecord
        case playing
        case readyToPlay
        case failed
    }

    var state = State.initial {
        didSet {
            delegate?.recordingController(self, didChangeStateTo: state)
        }
    }

    override init() {
        super.init()
        segmentRecorder = SegmentRecorderService(
            storage: storage,
            config: SegmentRecorderService.Config(
                segmentDuration: recDuration,
                quality: recordingQuality,
                maxSegmentSizeMB: segmentSizeMB
            )
        )
        segmentRecorder.delegate = self
    }

    func setupRecordingSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self?.state = .failed
                        print("Recording failed: please ensure the app has access to your microphone.")
                    }
                }
            }
        } catch {
            state = .failed
            print("Recording failed: \(error.localizedDescription)")
        }
    }

    func startPlaying() {
        let records = storage.getExistingRecordsArray().sorted { $0.date < $1.date }
        guard let latestRecord = records.last else {
            state = .readyToPlay
            return
        }

        state = .playing

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
            try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)

            player = try AVAudioPlayer(contentsOf: latestRecord.url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            state = .failed
            print("Cannot play recording: \(error.localizedDescription)")
        }
    }

    func finishPlaying(success: Bool) {
        player?.stop()
        player = nil
        state = success ? .readyToPlay : .failed
    }

    func toggleRecording() {
        if state == .recording {
            segmentRecorder.stop()
            storage.removeRecordsIfNeeded(maxCount: maxFiles)
            state = .readyToRecord
            return
        }

        segmentRecorder.start()
        state = .recording
    }

    func togglePlaying() {
        if state == .playing {
            finishPlaying(success: true)
            return
        }

        startPlaying()
    }

    func addMarker(note: String? = nil) {
        storage.addMarker(note: note)
    }

    func findRecord(at date: Date) -> Record? {
        storage.findRecord(at: date)
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishPlaying(success: flag)
    }

    // MARK: - SegmentRecorderServiceDelegate
    func segmentRecorderService(_ service: SegmentRecorderService, didStartSegment record: Record) {
        delegate?.recordingController(self, didUpdateMeteringLevel: 0)
    }

    func segmentRecorderService(_ service: SegmentRecorderService, didFinishSegment record: Record) {
        storage.removeRecordsIfNeeded(maxCount: maxFiles)
    }

    func segmentRecorderService(_ service: SegmentRecorderService, didUpdateMeteringLevel level: Float) {
        delegate?.recordingController(self, didUpdateMeteringLevel: level)
    }

    func segmentRecorderServiceDidFail(_ service: SegmentRecorderService) {
        state = .failed
    }
}
