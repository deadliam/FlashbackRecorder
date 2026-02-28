//
//  RecordingController.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecordingControllerDelegate: AnyObject {
    func recordingController(_ controller: RecordingController, didChangeStateTo state: RecordingController.State)
    func recordingController(_ controller: RecordingController, didUpdateMeteringLevel level: Float)
}

class RecordingController: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    weak var delegate: RecordingControllerDelegate?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var storage = RecordingStorage()
    
    private var recDuration: TimeInterval = 300 // 5 minutes default
    private var maxFiles = 50 // Store more recordings
    private var recordingQuality: AVAudioQuality = .high
    
    struct RecordingSettings {
        var duration: TimeInterval
        var quality: AVAudioQuality
        var maxRecordings: Int
    }
    
    var settings: RecordingSettings {
        get {
            return RecordingSettings(
                duration: recDuration,
                quality: recordingQuality,
                maxRecordings: maxFiles
            )
        }
        set {
            recDuration = newValue.duration
            recordingQuality = newValue.quality
            maxFiles = newValue.maxRecordings
        }
    }
    
    private var meteringTimer: Timer?
    
    override init() {
        super.init()
        state = State.initial
    }
    
    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let audioRecorder = self.audioRecorder else { return }
            audioRecorder.updateMeters()
            let level = audioRecorder.averagePower(forChannel: 0)
            // Convert to a 0-1 scale
            let normalizedLevel = pow(10, level/20)
            self.delegate?.recordingController(self, didUpdateMeteringLevel: normalizedLevel)
        }
    }
    
    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }
    
    func errorPermisions() {
        print("Recording failed: please ensure the app has access to your microphone.")
    }
    
    func setupRecordingSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Allowed to record")
                    } else {
                        self?.errorPermisions()
                    }
                }
            }
        } catch {
            self.errorPermisions()
        }
    }
    
    func startRecording() throws {
        storage.createRecordsDirectoryIfNotExists()
        print("Recording started")
        
        let newAudioRecord = storage.createNewRecord(at: Date())
        
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: recordingQuality == .high ? 44100 : 22050,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: recordingQuality.rawValue,
            AVEncoderBitRateKey: recordingQuality == .high ? 128000 : 64000
        ]

        do {
            let recordURL = storage.recordURL(for: newAudioRecord.title)
            audioRecorder = try AVAudioRecorder(url: recordURL, settings: recorderSettings)
            guard let audioRecorder = audioRecorder else {
                finishRecording(success: false)
                return
            }
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record(forDuration: recDuration)
            startMetering()
        } catch {
            finishRecording(success: false)
        }
    }
        
    func startPlaying() {
        let records = storage.getExistingRecordsArray()
        if records.isEmpty {
            state = State.readyToPlay
            print("There is no records")
            return
        }
        state = State.playing
        
        do {
            guard let latestRecord = records.last else {
                state = .readyToPlay
                return
            }
            let url = latestRecord.url
            
            print("Play: \(String(describing: url))")
            
            try recordingSession.setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
            try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            if try url.checkResourceIsReachable() {
                print("FILE AVAILABLE")
            } else {
                print("FILE NOT AVAILABLE")
            }
// ==========================================================
// Player doesn't play current url :(
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else {
                state = .failed
                return
            }
            player.prepareToPlay()
            player.play()
            
        } catch let error {
            state = State.readyToPlay
            print(error.localizedDescription)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishPlaying(success: true)
    }
    
    func finishRecording(success: Bool) {
        stopMetering()
        audioRecorder?.stop()
        audioRecorder = nil
        print("Recording finished")
        if success {
            state = State.readyToRecord
        } else {
            state = State.failed
            // recording failed :(
        }

        storage.removeRecordsIfNeeded(maxCount: maxFiles)
    }

    func finishPlaying(success: Bool) {
        player?.stop()
        player = nil
        print("Playing finished")
        if success {
            state = State.readyToPlay
        } else {
            state = State.failed
            // playing failed :(
        }
    }
    
    func toggleRecording() {
        if state == .recording {
            finishRecording(success: true)
            return
        }

        if audioRecorder == nil {
            do {
                try startRecording()
                state = State.recording
            } catch {
                print("Can not start record")
            }
        } else {
            finishRecording(success: true)
        }
    }
    
    func togglePlaying() {
        if state == .playing {
            finishPlaying(success: true)
            return
        }

        if player == nil {
            startPlaying()
        } else {
            finishPlaying(success: true)
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
    
//    var onStateChange: ((State) -> Void)?
    
    enum RecordingServiceError: String, Error {
        case canNotCreatePath = "Can not create path for new recording"
    }
}
