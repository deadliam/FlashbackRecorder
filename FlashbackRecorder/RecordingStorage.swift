//
//  RecordingStorage.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation

class RecordingStorage {
    
    private var record: Record!
    private var documentsDirUrl: URL!
    

    func makeRecordingURL() -> URL {
        let now: Date = Date.init(timeIntervalSinceNow: 0)
        let caldate: String = now.toString(dateFormat: "yyyy-MM-dd_HH-mm-ss")
        let recorderFilePath = String(format: "%@/flashback-record-%@.m4a", self.getDocumentsDirectoryURL().path, caldate)
        return URL(string: recorderFilePath)!
    }
    
    func getDocumentsDirectoryURL() -> URL {
        do {
            // Все что относиться к файл менеджеру тоже лучше где-то вынести. RecordingController например занимался бы всем что касается записью, а RecordingStorage всем что касается сохранением / удалением
            let manager = FileManager.default
            documentsDirUrl = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            print("Can not read documents dir!")
        }
        return documentsDirUrl
    }
    
    func getRecordsArray() -> [Record] {
        var records = [Record]()
        func meetsRequirement(name: String) -> Bool { return name.hasPrefix("flashback-record-") && name.hasSuffix("m4a") }
        do {
            let manager = FileManager.default
            if manager.changeCurrentDirectoryPath(getDocumentsDirectoryURL().path) {
                for filePath in try manager.contentsOfDirectory(atPath: ".") {
                    if meetsRequirement(name: filePath) {
                        let createdDate = manager.createdDateForFile(atPath: filePath)
                        records.append(Record(title: filePath, filePath: ".", date: createdDate))
                    }
                }
            }
        }
        catch {
            print("Cannot read Documents dir")
        }
        return records
    }
    
    func removeRecord(name: String) {
        do {
            let fileName = getDocumentsDirectoryURL().appendingPathComponent(name)
            try FileManager.default.removeItem(at: fileName)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
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
//        cleanupButton.backgroundColor = UIColor.blue
//        cleanupButton.setTitle("Cleaned", for: .normal)
    }
}

class Record {
    var title: String
    var date: Date
    var filePath: String
    
    public init(title: String, filePath: String, date: Date) {
        self.title = title
        self.filePath = filePath
        self.date = date
    }
}
