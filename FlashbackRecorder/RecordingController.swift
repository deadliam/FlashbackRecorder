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
}

class RecordingController: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    weak var delegate: RecordingControllerDelegate?
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var player: AVAudioPlayer?
    private var storage = RecordingStorage()
    
    private let recDuration: TimeInterval = 10 // seconds
    private let maxFiles = 5
    
    override init() {
        super.init()
        self.state = State.initial
        self.player?.delegate = self
    }
    
    func errorPermisions() {
        print("Recording failed: please ensure the app has access to your microphone.")
    }
    
    func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Allowed to record")
//                        self.setupRecordButton()
                    } else {
//                        self.setupFailUI(text: "Recording failed: please ensure the app has access to your microphone.")
                        self.errorPermisions()
                    }
                }
            }
        } catch {
//            self.setupFailUI(text: "Recording failed: please ensure the app has access to your microphone.")
            self.errorPermisions()
        }
    }
    
    func startRec() throws {
        
        storage.createRecordsDir()
        print("Recording started")
        
        guard let newAudioFileUrl = storage.createURLForNewRecord() else {
            throw RecordingServiceError.canNotCreatePath
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: newAudioFileUrl, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record(forDuration: recDuration)
            
        } catch {
            finishRecording(success: false)
        }
        
        let records = storage.getRecordsArray()
        if !records.isEmpty && records.count > maxFiles {
            storage.removeRecord(name: records.first!.title)
        }
    }
        
    func play() {
    //        guard let url = Bundle.main.url(forResource: "recording", withExtension: "m4a") else { return }
        let storage = RecordingStorage()
        let records = storage.getRecordsArray()
        if records.isEmpty {
//            self.setupFailUI(text: "There is no records")
            return
        }
        do {
            let url = storage.getRecordsDirectoryURL().appendingPathComponent(records.last!.title)
            
            print("FILE: \(url)")
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            
            player?.delegate = self
            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }
            player.prepareToPlay()
//            player.volume = 1.0
            player.play()
            
            print("Playing: \(url)")
        } catch let error {
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
        audioRecorder.stop()
        audioRecorder = nil
        print("Recording finished")
        if success {
            self.state = State.readyToRecord
        } else {
            self.state = State.failed
            // recording failed :(
        }
    }

    func finishPlaying(success: Bool) {
        player?.stop()
        player = nil
        print("Playing finished")
        if success {
            self.state = State.readyToPlay
        } else {
            self.state = State.failed
            // playing failed :(
        }
    }
    
    func toggleRecording() {
        if audioRecorder == nil {
            do {
                try startRec()
                self.state = State.recording
            } catch {
                print("Can not start record")
            }
        } else {
            finishRecording(success: true)
            self.state = State.readyToRecord
        }
    }
    
    func togglePlaying() {
        if player == nil {
            play()
            self.state = State.playing
        } else {
            finishPlaying(success: true)
            self.state = State.readyToPlay
        }
    }
    
    enum State {
        case recording
        case readyToRecord
        case playing
        case readyToPlay
        case failed
        case initial
    }
    
    var state = State.initial {
        didSet {
//            onStateChange?(state)
            delegate?.recordingController(self, didChangeStateTo: state)
        }
    }
    
//    var onStateChange: ((State) -> Void)?
    
    enum RecordingServiceError: String, Error {
        case canNotCreatePath = "Can not create path for new recording"
    }
}
