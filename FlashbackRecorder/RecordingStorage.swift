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
    private let recordPrefix = "flashback-record-"
    private let recordExtension = ".m4a"
    private let recordsDirectoryName = "Records"
    
    func createNewRecord() -> Record {
        let now: Date = Date.init(timeIntervalSinceNow: 0)
        let fileNameDate: String = now.toString(dateFormat: "yyyy-MM-dd_HH-mm-ss")
        return Record(title: recordPrefix + fileNameDate + recordExtension, date: now)
    }
    
    func createRecordsDirectoryIfNotExists() {
        let recordsDirectory = FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: recordsDirectory.path) {
            do {
                try FileManager.default.createDirectory(atPath: recordsDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create Records directory")
            }
        }
    }
    
    func parseRecordDetails(fileURL: URL) -> Record {
        let manager = FileManager.default
        let titleWithExtension = fileURL.lastPathComponent
//        let creationDate = manager.lastCreated(path: filePathAndName)
        let creationDate = manager.creationDate(for: fileURL)
        return Record(title: String(describing: titleWithExtension), date: creationDate)
    }
    
    // сохранять json с записями и на старте апки читать
    func getExistingRecordsArray() -> [Record] {
        var records = [Record]()
        func meetsRequirement(name: String) -> Bool { return name.contains(recordPrefix) && name.hasSuffix(recordExtension) }
        do {
            let manager = FileManager.default
            let recordsDirectory = FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName, isDirectory: true)
            // if Records directory exists
            if manager.fileExists(atPath: recordsDirectory.path) {
                let files = try manager.contentsOfDirectory(atPath: recordsDirectory.path)
                for fileName in files {
                    if meetsRequirement(name: fileName) {
                        
                        let record = parseRecordDetails(fileURL: recordsDirectory.appendingPathComponent(fileName))
                        records.append(record)
                    }
                }
            }
        }
        catch {
            print("Cannot read Documents dir")
        }
//        print("RECORDS: \(records.count)")
//        print("FIRST: \(String(describing: records.first?.title)) ==== LAST: \(String(describing: records.last?.title))")
        return records
    }
    
    func removeRecord(name: String) {
        do {
            let fileName = FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName).appendingPathComponent(name)
            try FileManager.default.removeItem(at: fileName)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    func toggleListing() {
        do {
            let manager = FileManager.default
            let files = try manager.contentsOfDirectory(atPath: FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName).path)
            if !files.isEmpty {
                for file in files {
                    print(file)
                }
            } else {
                print("There is nothing to list :(")
            }
        }
        catch {
            print("Cannot list files. \(error)")
        }
    }
    
    
    func toggleCleaning() {
//        let maximumDays = 1.0
//        let minimumDate = Date().addingTimeInterval(-maximumDays*24*60*60)
//        func meetsRequirement(date: Date) -> Bool { return date < minimumDate }
        
        func meetsRequirement(name: String) -> Bool { return name.contains(recordPrefix) && name.hasSuffix(recordExtension) }
        do {
            let manager = FileManager.default
            for file in try manager.contentsOfDirectory(at: FileManager.documentDirectoryURL.appendingPathComponent(recordsDirectoryName), includingPropertiesForKeys: []) {
//                    let creationDate = try manager.attributesOfItem(atPath: file)[FileAttributeKey.creationDate] as! Date
//                    if meetsRequirement(name: file) && meetsRequirement(date: creationDate) {
                if meetsRequirement(name: file.path) {
                    try manager.removeItem(at: file)
                    print("Removed: \(file.path)")
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
    
    public init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}
