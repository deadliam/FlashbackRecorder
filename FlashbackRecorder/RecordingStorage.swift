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
    
    func createURLForNewRecord() -> URL? {
        
        let appGroupFolderUrl = getRecordsDirectoryURL()
    
        let now: Date = Date.init(timeIntervalSinceNow: 0)
        let fileNameDatePrefix: String = now.toString(dateFormat: "yyyy-MM-dd_HH-mm-ss")
        let fullFileName = "flashback-record-" + fileNameDatePrefix + ".m4a"
        let newRecordFileName = appGroupFolderUrl.appendingPathComponent(fullFileName)
        
        return newRecordFileName
    }
    
//    func makeRecordingURL() -> URL {
//        let now: Date = Date.init(timeIntervalSinceNow: 0)
//        let caldate: String = now.toString(dateFormat: "yyyy-MM-dd_HH-mm-ss")
//        let recorderFilePath = String(format: "%@/flashback-record-%@.m4a", self.getRecordsDirectoryURL().path, caldate)
//        return URL(string: recorderFilePath)!
//    }
    
//    func getDocumentsDirectoryURL() -> URL {
//        let documentsDirUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return documentsDirUrls
//    }
    
    func getRecordsDirectoryURL() -> URL {
        return FileManager.documentDirectoryURL.appendingPathComponent("Records")
    }
    
    func createRecordsDir() {
        let recDir = getRecordsDirectoryURL()
        if !FileManager.default.fileExists(atPath: recDir.path) {
            do {
                try FileManager.default.createDirectory(atPath: recDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create Records directory")
            }
        }
    }
    
    // сохранять json с записями и на старте апки читать
    func getRecordsArray() -> [Record] {
        var records = [Record]()
        func meetsRequirement(name: String) -> Bool { return name.hasPrefix("flashback-record-") && name.hasSuffix("m4a") }
        do {
            let manager = FileManager.default
            if manager.changeCurrentDirectoryPath(getRecordsDirectoryURL().path) {
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
//        print("RECORDS: \(records.count)")
//        print("FIRST: \(String(describing: records.first?.title)) ==== LAST: \(String(describing: records.last?.title))")
        return records
    }
    
    func removeRecord(name: String) {
        do {
            let fileName = getRecordsDirectoryURL().appendingPathComponent(name)
            try FileManager.default.removeItem(at: fileName)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    func toggleListing() {
        do {
            let manager = FileManager.default
            for file in try manager.contentsOfDirectory(atPath: getRecordsDirectoryURL().path) {
                print(file)
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
        
        func meetsRequirement(name: String) -> Bool { return name.hasPrefix("flashback-record-") && name.hasSuffix("m4a") }

        do {
            let manager = FileManager.default
            for file in try manager.contentsOfDirectory(atPath: getRecordsDirectoryURL().path) {
//                    let creationDate = try manager.attributesOfItem(atPath: file)[FileAttributeKey.creationDate] as! Date
//                    if meetsRequirement(name: file) && meetsRequirement(date: creationDate) {
                if meetsRequirement(name: file) {
                    try manager.removeItem(atPath: file)
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
