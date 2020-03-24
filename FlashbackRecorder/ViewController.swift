//
//  ViewController.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 23.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications

class ViewController: BaseScrollViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var recordButton: UIButton!
    var playButton: UIButton!
    var cleanupButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var player: AVAudioPlayer?
    var failLabel: UILabel!
    var label: UILabel!
    var stackView: UIStackView!
   
    let maxFiles = 5
    let recDuration: TimeInterval = 10 // seconds
    var documentsDirUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        stackView = UIStackView()
    
        do {
            let manager = FileManager.default
            documentsDirUrl = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            print("Can not read documents dir!")
        }
        
        createStackView()
        createTable()
        
        print(recordsInDocumentsDir())
        
        player?.delegate = self
        self.loadPlayButton()
        self.loadCleanupRecordsButton()
//        self.loadTextLabel(text: "")
        
        print(FileManager.default.urls(for: .documentDirectory) ?? "none")
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordButton()
                    } else {
                        self.loadFailUI(text: "Recording failed: please ensure the app has access to your microphone.")
                        print("Failed to record!")
                    }
                }
            }
        } catch {
            self.loadFailUI(text: "Recording failed: please ensure the app has access to your microphone.")
            print("Failed to record!")
        }
    }
    
    func createStackView() {
        stackView.removeFromSuperview()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.distribution = .fill
        scrollView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          // Attaching the content's edges to the scroll view's edges
          stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
          stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
          stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
          stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

          // Satisfying size constraints
          stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func createTable() {
        let contentsOfDocuments = recordsInDocumentsDir()
        for i in 0...5 {
            let listView = UIView()
            listView.backgroundColor = .gray
            stackView.addArrangedSubview(listView)
            listView.translatesAutoresizingMaskIntoConstraints = false
            // Doesn't have intrinsic content size, so we have to provide the height at least
            listView.heightAnchor.constraint(equalToConstant: 0).isActive = true

            // Label (has instrinsic content size)
            let label = UILabel()
            label.font = label.font.withSize(25)
            label.backgroundColor = .orange
            if contentsOfDocuments.indices.contains(i) {
                let labelText = contentsOfDocuments[i].dropFirst(10).dropLast(4)
                label.text = String(labelText)
            } else {
                break
            }
            label.textAlignment = .left
            stackView.addArrangedSubview(label)
        }
    }
        
    func getRecordingURL() -> URL {
        let now: Date = Date.init(timeIntervalSinceNow: 0)
        let caldate: String = now.toString(dateFormat: "yyyy-MM-dd_HH-mm-ss")
        let recorderFilePath = String(format: "%@/flashback-record-%@.m4a", self.getDocumentsDirectory().path, caldate)
        return URL(string: recorderFilePath)!
    }

    func loadRecordButton() {
        recordButton = UIButton(frame: CGRect(x: 10, y: 30, width: 160, height: 64))
        recordButton.backgroundColor = UIColor.red
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    func loadPlayButton() {
        playButton = UIButton(frame: CGRect(x: 200, y: 30, width: 160, height: 64))
        playButton.backgroundColor = UIColor.green
        playButton.setTitle("Play", for: .normal)
        playButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        view.addSubview(playButton)
    }
    
    func loadCleanupRecordsButton() {
        cleanupButton = UIButton(frame: CGRect(x: 10, y: 110, width: 160, height: 64))
        cleanupButton.backgroundColor = UIColor.magenta
        cleanupButton.setTitle("CleanUp", for: .normal)
        cleanupButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        cleanupButton.addTarget(self, action: #selector(cleanUp), for: .touchUpInside)
        view.addSubview(cleanupButton)
    }
    
    func loadFailUI(text: String) {
        failLabel = UILabel(frame: CGRect(x: 0, y: 280, width: 300, height: 128))
        failLabel.textColor = UIColor.red
        failLabel.center = CGPoint(x: 160, y: 400)
        failLabel.textAlignment = NSTextAlignment.center
//        failLabel.backgroundColor = UIColor.blue
        failLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        failLabel.text = text
        failLabel.numberOfLines = 2
        self.view.addSubview(failLabel)
        hideLabel(label: failLabel, duration: 3)
    }
    
    func loadTextLabel(text: String) {
        label = UILabel(frame: CGRect(x: 0, y: 550, width: 300, height: 128))
        label.textColor = UIColor.white
        label.center = CGPoint(x: 160, y: 550)
        label.textAlignment = NSTextAlignment.center
//        label.backgroundColor = UIColor.gray
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.text = text
        label.numberOfLines = 2
        self.view.addSubview(label)
    }

    func startRecording() {
        
        let audioFilename = getRecordingURL()
        
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
        
        let records = self.recordsInDocumentsDir()
        if !records.isEmpty && records.count > maxFiles {
            removeRecord(name: records.first!)
        }
        print("RECORDS: \(self.recordsInDocumentsDir().count)")
        print("FIRST: \(self.recordsInDocumentsDir().first!) ==== LAST: \(self.recordsInDocumentsDir().last!)")
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
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
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    @objc func playTapped() {
        if player == nil {
            playButton.setTitle("Stop", for: .normal)
            playSound()
        } else {
            finishPlaying(success: true)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("finished recording")
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func playSound() {
//        guard let url = Bundle.main.url(forResource: "recording", withExtension: "m4a") else { return }
        
        let records = self.recordsInDocumentsDir()
        if records.isEmpty {
            self.loadFailUI(text: "There is no records")
            return
        }
        let url = getDocumentsDirectory().appendingPathComponent(records.last!)
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
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing")
        finishPlaying(success: true)
    }
    
    func getFileCreatedDate(theFile: String) -> Date {

        var theCreationDate = Date()
        do{
            let aFileAttributes = try FileManager.default.attributesOfItem(atPath: theFile) as [FileAttributeKey: Any]
            theCreationDate = aFileAttributes[FileAttributeKey.creationDate] as! Date

        } catch let theError {
            print("file not found \(theError)")
        }
        return theCreationDate
    }
    
    @objc func cleanUp() {
        let maximumDays = 1.0
        let minimumDate = Date().addingTimeInterval(-maximumDays*24*60*60)
        func meetsRequirement(date: Date) -> Bool { return date < minimumDate }

        func meetsRequirement(name: String) -> Bool { return name.hasPrefix("flashback-record-") && name.hasSuffix("m4a") }

        do {
            let manager = FileManager.default
            if manager.changeCurrentDirectoryPath(documentsDirUrl.path) {
                for file in try manager.contentsOfDirectory(atPath: ".") {
//                    let creationDate = try manager.attributesOfItem(atPath: file)[FileAttributeKey.creationDate] as! Date
//                    if meetsRequirement(name: file) && meetsRequirement(date: creationDate) {
                    if meetsRequirement(name: file) {
                        try manager.removeItem(atPath: file)
                    }
                }
            }
        }
        catch {
            print("Cannot cleanup the old files: \(error)")
        }
        cleanupButton.backgroundColor = UIColor.blue
        cleanupButton.setTitle("Cleaned", for: .normal)
    }
    
    func recordsInDocumentsDir() -> Array<String> {
        var files = [String]()
        func meetsRequirement(name: String) -> Bool { return name.hasPrefix("") && name.hasSuffix("m4a") }
        do {
            let manager = FileManager.default
            if manager.changeCurrentDirectoryPath(documentsDirUrl.path) {
                for file in try manager.contentsOfDirectory(atPath: ".") {
                    if meetsRequirement(name: file) {
                        files.append(file)
                    }
                }
            }
        }
        catch {
            print("Cannot read Documents dir")
        }
        return files
    }
    
    func removeRecord(name: String) {
        do {
            let fileName = documentsDirUrl.appendingPathComponent(name)
            try FileManager.default.removeItem(at: fileName)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    func hideLabel(label: UILabel, duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.label.isHidden = true
        }
    }
    
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        let center = UNUserNotificationCenter.current()
//        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
//            // If granted comes true you can enabled features based on authorization.
//            guard granted else { return }
//            DispatchQueue.main.async {
//                application.registerForRemoteNotifications()
//            }
//        }
//        return true
//    }
}

extension FileManager {
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}

extension Date {
    func toString( dateFormat format  : String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

// https://stackoverflow.com/questions/16276611/record-voice-in-backgroundwhen-i-tapped-home-button-using-avaudiorecorder
// https://stackoverflow.com/questions/1010343/how-do-i-record-audio-on-iphone-with-avaudiorecorder/1011273#1011273
