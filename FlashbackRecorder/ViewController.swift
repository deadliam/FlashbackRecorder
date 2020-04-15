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

class ViewController: BaseScrollViewController, RecordingControllerDelegate {
    func recordingController(_ controller: RecordingController, didChangeStateTo state: RecordingController.State) {
        updateUIButtons(state: state)
    }
    
    private var recordButton: UIButton!
    private var playButton: UIButton!
    private var cleanButton: UIButton!
    private var recordingController: RecordingController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overrideUserInterfaceStyle = .dark
//        self.navigationItem.title = "Recorder"
//        self.navigationController?.navigationBar.prefersLargeTitles = true
    
        recordingController = RecordingController()
        recordingController.delegate = self
        //        recordingController.onStateChange = {[weak self] state in
        //           self?.updateUI(state: state)
        //        }
        recordingController.setupRecordingSession()
        
//        RecordsTableView().setupStackView()
//        RecordsTableView().setupTable()
        
        recordButton = ButtonBuilder.createButton(name: "Record", color: .red, target: self, action: #selector(toggleRecording))
        view.addSubview(recordButton)
        setButtonConstraints(button: recordButton, positionY: 50)
        
        playButton = ButtonBuilder.createButton(name: "Play", color: .green, target: self, action: #selector(togglePlaying))
        view.addSubview(playButton)
        setButtonConstraints(button: playButton, positionY: 150)
        
        cleanButton = ButtonBuilder.createButton(name: "Clean", color: .orange, target: self, action: #selector(toggleCleaning))
        view.addSubview(cleanButton)
        setButtonConstraints(button: cleanButton, positionY: 300)
    }
    
    func setButtonConstraints(button: UIButton, positionY: CGFloat) {
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: positionY).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50).isActive = true
    }
    
    func updateUIButtons(state: RecordingController.State) {
        switch state {
        case .recording:
            recordButton.setTitle("Stop", for: .normal)
        case .readyToRecord:
            recordButton.setTitle("Record", for: .normal)
        case .playing:
            playButton.setTitle("Stop", for: .normal)
        case .readyToPlay:
            playButton.setTitle("Play", for: .normal)
        default:
            recordButton.setTitle("Record", for: .normal)
            playButton.setTitle("Play", for: .normal)
        }
    }
    
//    func updateUIPlayButton(state: RecordingController.State) {
//        switch state {
//        case .playing:
//            playButton.setTitle("Stop", for: .normal)
//        case .readyToPlay:
//            playButton.setTitle("Play", for: .normal)
//        default:
//            playButton.setTitle("Undefined", for: .normal)
//        }
//    }

    @objc func toggleRecording() {
        recordingController.toggleRecording()
    }
    
    @objc func togglePlaying() {
        recordingController.togglePlaying()
    }
    
    @objc func toggleCleaning() {
        recordingController.toggleCleaning()
    }
    
    // Вот это не совсем правильно. По сути лейблу можно добавить один раз во вью, а дальше просто менять ее свойство hidden. Изначально она должна быть спрятана видимо
//    func setupFailUI(text: String) {
//        failLabel = UILabel(frame: CGRect(x: 0, y: 280, width: 300, height: 128))
//        failLabel.textColor = UIColor.red
//        failLabel.center = CGPoint(x: 160, y: 400)
//        failLabel.textAlignment = NSTextAlignment.center
////        failLabel.backgroundColor = UIColor.blue
//        failLabel.font = UIFont.preferredFont(forTextStyle: .headline)
//        failLabel.text = text
//        failLabel.numberOfLines = 2
//        self.view.addSubview(failLabel)
//
//        hideLabel(label: failLabel, duration: 3)
//    }
    
    //
    
//    func setupTextLabel(text: String) {
//        label = UILabel(frame: CGRect(x: 0, y: 550, width: 300, height: 128))
//        label.textColor = UIColor.white
//        label.center = CGPoint(x: 160, y: 550)
//        label.textAlignment = NSTextAlignment.center
////        label.backgroundColor = UIColor.gray
//        label.font = UIFont.preferredFont(forTextStyle: .headline)
//        label.text = text
//        label.numberOfLines = 2
//        self.view.addSubview(label)
//    }


    
    // здесь было бы что-то типа
//    if recordingController.isRecording {
//        recordingController.stop()
//    } else {
//        recordingController.start()
//    }

    
    
    // Для того чтоб правильно менять тайтл кнопки надо было бы чтоб у RecordingStorage было бы свойство hasSavedRecords или как-то так, и когда оно меняется - менять тайтл кнопки. как вариант ViewController мог бы быть делегатом RecordingStorage и RecordingStorage дергал бы методы типа func  recordingStorageDidCleanUpRecordings(storage: RecordingStorage) у этого делегата (делегат это по сути протокол со списками методов. Эти методы бы имплеметировались во вью контроллере а сторедж бы их взывал при завершении операций)
    // эту же логику с делегатом но уже другим можно было бы использовать для recordingsController чтоб следить за состоянием записи (и например выводить ошибку если что-то поло не так)
    
 
//    func hideLabel(label: UILabel, duration: TimeInterval) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//            self.label.isHidden = true
//        }
//    }
    
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



// https://stackoverflow.com/questions/16276611/record-voice-in-backgroundwhen-i-tapped-home-button-using-avaudiorecorder
// https://stackoverflow.com/questions/1010343/how-do-i-record-audio-on-iphone-with-avaudiorecorder/1011273#1011273
