import Foundation

final class RecordingStorage {
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

    private lazy var indexStore: SegmentIndexStore = {
        let dbURL = recordsDirectoryURL.appendingPathComponent("segments.sqlite")
        return SegmentIndexStore(databaseURL: dbURL)
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

    func indexSegmentStart(_ record: Record) {
        indexStore.upsertSegment(fileName: record.title, startAt: record.date, endAt: record.endDate, sizeBytes: record.sizeBytes)
    }

    func indexSegmentEnd(fileName: String, endAt: Date, sizeBytes: Int64) {
        indexStore.updateSegmentEnd(fileName: fileName, endAt: endAt, sizeBytes: sizeBytes)
    }

    func getExistingRecordsArray() -> [Record] {
        createRecordsDirectoryIfNotExists()

        let indexed = indexStore.fetchSegments()
        if !indexed.isEmpty {
            return indexed
        }

        // Bootstrap index from existing files once.
        let scanned = scanRecordsFromFilesystem().sorted { $0.date > $1.date }
        scanned.forEach { indexStore.upsertSegment(fileName: $0.title, startAt: $0.date, endAt: $0.endDate, sizeBytes: $0.sizeBytes) }
        return scanned
    }

    func getRecords(from: Date?, to: Date?, limit: Int? = nil) -> [Record] {
        indexStore.fetchSegments(from: from, to: to, limit: limit)
    }

    func findRecord(at date: Date) -> Record? {
        indexStore.findSegment(at: date)
    }

    func removeRecord(name: String) {
        do {
            let fileURL = recordURL(for: name)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            indexStore.deleteSegment(fileName: name)
        } catch {
            print("Cannot remove record \(name): \(error.localizedDescription)")
        }
    }

    func removeRecordsIfNeeded(maxCount: Int) {
        guard maxCount > 0 else { return }
        let records = getExistingRecordsArray().sorted { $0.date < $1.date }
        guard records.count > maxCount else { return }

        let excessCount = records.count - maxCount
        records.prefix(excessCount).forEach { removeRecord(name: $0.title) }
    }

    func deleteAllRecords() {
        getExistingRecordsArray().forEach { removeRecord(name: $0.title) }
        indexStore.clearSegments()
    }

    func addMarker(at date: Date = Date(), note: String? = nil) {
        _ = indexStore.addMarker(at: date, note: note)
    }

    func fetchMarkers(from: Date? = nil, to: Date? = nil, limit: Int = 200) -> [MarkerRecord] {
        indexStore.fetchMarkers(from: from, to: to, limit: limit)
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

    private func scanRecordsFromFilesystem() -> [Record] {
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: recordsDirectoryURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            return urls.compactMap { url -> Record? in
                let fileName = url.lastPathComponent
                guard fileName.hasPrefix(recordPrefix), url.pathExtension == recordExtension else {
                    return nil
                }

                let values = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                let creationDate = values?.creationDate ?? Date()
                let fileSize = values?.fileSize.map(Int64.init) ?? 0
                return Record(title: fileName, date: creationDate, endDate: nil, sizeBytes: fileSize)
            }
        } catch {
            print("Cannot read records directory: \(error.localizedDescription)")
            return []
        }
    }
}
