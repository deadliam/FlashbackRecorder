//
//  RecordingController.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import AVFoundation

class RecordingController: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var player: AVAudioPlayer?
    var recordButton: RecordButton!
    var playButton: PlayButton!
    
    let recDuration: TimeInterval = 10 // seconds
    let maxFiles = 5
    
    override init() {
        super.init()
        self.recordButton = RecordButton()
        self.playButton = PlayButton()
        self.player?.delegate = self
    }
    
    func errorPermisions() {
        print("Recording failed: please ensure the app has access to your microphone.")
    }
    
    ///////////////////////////
    // тут логика завязана на UI, что с этим делать?
    func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("")
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
    
    func startRec() {
        let storage = RecordingStorage()
        let audioFilename = storage.makeRecordingURL()

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record(forDuration: recDuration)
            recordButton.setTitle("Stop", for: .normal)
            
        } catch {
            finishRecording(success: false)
        }
        
        let records = storage.getRecordsArray()
        if !records.isEmpty && records.count > maxFiles {
            storage.removeRecord(name: records.first!.filePath)
        }
//        print("RECORDS: \(self.recordsInDocumentsDir().count)")
//        print("FIRST: \(self.recordsInDocumentsDir().first!) ==== LAST: \(self.recordsInDocumentsDir().last!)")
    }
        
    func play() {
    //        guard let url = Bundle.main.url(forResource: "recording", withExtension: "m4a") else { return }
        let storage = RecordingStorage()
        let records = storage.getRecordsArray()
        if records.isEmpty {
//            self.setupFailUI(text: "There is no records")
            return
        }
        let url = storage.getDocumentsDirectoryURL().appendingPathComponent(records.last!.filePath)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue)
            
            player?.delegate = self
            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }
            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("finished recording")
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing")
        finishPlaying(success: true)
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
       
        if success {
            recordButton.setTitle("Tap to Record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }

    func finishPlaying(success: Bool) {
        player?.stop()
        player = nil
       
        if success {
            playButton.setTitle("Play", for: .normal)
        } else {
            playButton.setTitle("Failed", for: .normal)
            // playing failed :(
        }
    }
    
    func toggleRecording() {
        if audioRecorder == nil {
            startRec()
        } else {
            finishRecording(success: true)
        }
    }
    
    func togglePlaying() {
        if player == nil {
            playButton.setTitle("Stop", for: .normal)
            play()
        } else {
            finishPlaying(success: true)
        }
    }
    
    func toggleCleaning() {
        
    }
}
