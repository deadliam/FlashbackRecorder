//
//  RecordingStorage.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation

class RecordingStorage {

    private let fileManager = FileManager.default
    private let recordPrefix = "flashback-record-"
    private let recordExtension = "m4a"
    private let recordsDirectoryName = "Records"

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    var recordsDirectoryURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(recordsDirectoryName, isDirectory: true)
    }

    func createRecordsDirectoryIfNotExists() {
        guard !fileManager.fileExists(atPath: recordsDirectoryURL.path) else { return }
        do {
            try fileManager.createDirectory(
                at: recordsDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            NSLog("Couldn't create Records directory: \(error.localizedDescription)")
        }
    }

    func createNewRecord(at date: Date = Date()) -> Record {
        let timestamp = dateFormatter.string(from: date)
        let fileName = "\(recordPrefix)\(timestamp).\(recordExtension)"
        return Record(title: fileName, date: date)
    }

    func recordURL(for fileName: String) -> URL {
        recordsDirectoryURL.appendingPathComponent(fileName)
    }

    private func parseRecordDetails(fileURL: URL) -> Record {
        let creationDate = fileManager.creationDate(for: fileURL)
        return Record(title: fileURL.lastPathComponent, date: creationDate)
    }

    func getExistingRecordsArray() -> [Record] {
        createRecordsDirectoryIfNotExists()

        do {
            let urls = try fileManager.contentsOfDirectory(
                at: recordsDirectoryURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            return urls
                .filter { url in
                    let fileName = url.lastPathComponent
                    return fileName.hasPrefix(recordPrefix) && url.pathExtension == recordExtension
                }
                .map(parseRecordDetails(fileURL:))
                .sorted { $0.date < $1.date }
        } catch {
            print("Cannot read records directory: \(error.localizedDescription)")
            return []
        }
    }

    func removeRecord(name: String) {
        do {
            let fileURL = recordURL(for: name)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Cannot remove record \(name): \(error.localizedDescription)")
        }
    }

    func removeRecordsIfNeeded(maxCount: Int) {
        guard maxCount > 0 else { return }
        let records = getExistingRecordsArray()
        guard records.count > maxCount else { return }

        let excessCount = records.count - maxCount
        records.prefix(excessCount).forEach { removeRecord(name: $0.title) }
    }

    func deleteAllRecords() {
        getExistingRecordsArray().forEach { removeRecord(name: $0.title) }
    }

    func toggleListing() {
        let records = getExistingRecordsArray()
        if records.isEmpty {
            print("There is nothing to list :(")
            return
        }

        records.forEach { print($0.title) }
    }

    // Backward-compatible wrapper used by existing UI.
    func toggleCleaning() {
        deleteAllRecords()
    }
}

class Record {
    var title: String
    var date: Date

    var url: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory
            .appendingPathComponent("Records", isDirectory: true)
            .appendingPathComponent(title)
    }

    public init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}
