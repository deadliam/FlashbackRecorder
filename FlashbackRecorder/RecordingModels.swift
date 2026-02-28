import Foundation

final class Record {
    let title: String
    let date: Date
    let endDate: Date?
    let sizeBytes: Int64

    init(title: String, date: Date, endDate: Date? = nil, sizeBytes: Int64 = 0) {
        self.title = title
        self.date = date
        self.endDate = endDate
        self.sizeBytes = sizeBytes
    }

    var url: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory
            .appendingPathComponent("Records", isDirectory: true)
            .appendingPathComponent(title)
    }
}

struct MarkerRecord {
    let id: Int64
    let timestamp: Date
    let note: String?
}
