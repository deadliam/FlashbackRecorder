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
    private var player: AVAudioPlayer? = AVAudioPlayer()
    private var storage = RecordingStorage()
    
    private let recordsDirectoryName = "Records"
    
    private let recDuration: TimeInterval = 10 // seconds
    private let maxFiles = 5
    
    override init() {
        super.init()
        state = State.initial
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
    
    func startRecording() throws {
        
        storage.createRecordsDirectoryIfNotExists()
        print("Recording started")
        
        let newAudioRecord = storage.createNewRecord()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let documentsDirectory = FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName)
            audioRecorder = try AVAudioRecorder(url: documentsDirectory.appendingPathComponent(newAudioRecord.title), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record(forDuration: recDuration)
        } catch {
            finishRecording(success: false)
        }
        
        let records = storage.getExistingRecordsArray()
        
        if !records.isEmpty && records.count > maxFiles {
            storage.removeRecord(name: records.first!.title)
        }
    }
        
    func startPlaying() {
        let storage = RecordingStorage()
        let records = storage.getExistingRecordsArray()
        if records.isEmpty {
            state = State.readyToPlay
            print("There is no records")
            return
        }
        state = State.playing
        do {
            let documentsDirectory = FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName)
            let url = documentsDirectory.appendingPathComponent(records.last!.title)
            
            print("FILE: \(String(describing: url))")
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            
            player = try AVAudioPlayer(contentsOf: url)
            
            player?.delegate = self
            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }
            player.prepareToPlay()
//            player.volume = 1.0
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
        audioRecorder.stop()
        audioRecorder = nil
        print("Recording finished")
        if success {
            state = State.readyToRecord
        } else {
            state = State.failed
            // recording failed :(
        }
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
        if audioRecorder == nil {
            do {
                try startRecording()
                state = State.recording
            } catch {
                print("Can not start record")
            }
        } else {
            finishRecording(success: true)
            state = State.readyToRecord
        }
    }
    
    func togglePlaying() {
        if player == nil {
            startPlaying()
        } else {
            finishPlaying(success: true)
            state = State.readyToPlay
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
//            onStateChange?(state)
            delegate?.recordingController(self, didChangeStateTo: state)
        }
    }
    
//    var onStateChange: ((State) -> Void)?
    
    enum RecordingServiceError: String, Error {
        case canNotCreatePath = "Can not create path for new recording"
    }
}
