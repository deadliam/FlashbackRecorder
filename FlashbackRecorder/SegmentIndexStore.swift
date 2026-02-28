import Foundation
import SQLite3

final class SegmentIndexStore {
    private var db: OpaquePointer?
    private let databaseURL: URL

    init(databaseURL: URL) {
        self.databaseURL = databaseURL
        openDatabase()
        createSchemaIfNeeded()
    }

    deinit {
        sqlite3_close(db)
    }

    func upsertSegment(fileName: String, startAt: Date, endAt: Date?, sizeBytes: Int64) {
        let sql = """
        INSERT INTO segments (file_name, start_at, end_at, size_bytes)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(file_name) DO UPDATE SET
            start_at = excluded.start_at,
            end_at = excluded.end_at,
            size_bytes = excluded.size_bytes;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        bindText(statement, index: 1, value: fileName)
        sqlite3_bind_double(statement, 2, startAt.timeIntervalSince1970)
        if let endAt {
            sqlite3_bind_double(statement, 3, endAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_int64(statement, 4, sizeBytes)

        sqlite3_step(statement)
    }

    func updateSegmentEnd(fileName: String, endAt: Date, sizeBytes: Int64) {
        let sql = "UPDATE segments SET end_at = ?, size_bytes = ? WHERE file_name = ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, endAt.timeIntervalSince1970)
        sqlite3_bind_int64(statement, 2, sizeBytes)
        bindText(statement, index: 3, value: fileName)

        sqlite3_step(statement)
    }

    func fetchSegments(from: Date? = nil, to: Date? = nil, limit: Int? = nil) -> [Record] {
        var conditions: [String] = []
        if from != nil { conditions.append("start_at >= ?") }
        if to != nil { conditions.append("start_at <= ?") }

        var sql = "SELECT file_name, start_at, end_at, size_bytes FROM segments"
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }
        sql += " ORDER BY start_at DESC"
        if limit != nil {
            sql += " LIMIT ?"
        }
        sql += ";"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var bindIndex: Int32 = 1
        if let from {
            sqlite3_bind_double(statement, bindIndex, from.timeIntervalSince1970)
            bindIndex += 1
        }
        if let to {
            sqlite3_bind_double(statement, bindIndex, to.timeIntervalSince1970)
            bindIndex += 1
        }
        if let limit {
            sqlite3_bind_int(statement, bindIndex, Int32(limit))
        }

        var results: [Record] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let cName = sqlite3_column_text(statement, 0) else { continue }
            let fileName = String(cString: cName)
            let startAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))

            var endDate: Date?
            if sqlite3_column_type(statement, 2) != SQLITE_NULL {
                endDate = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            }

            let size = sqlite3_column_int64(statement, 3)
            results.append(Record(title: fileName, date: startAt, endDate: endDate, sizeBytes: size))
        }

        return results
    }

    func findSegment(at date: Date) -> Record? {
        let timestamp = date.timeIntervalSince1970

        let coveringSQL = """
        SELECT file_name, start_at, end_at, size_bytes
        FROM segments
        WHERE start_at <= ? AND (end_at IS NULL OR end_at >= ?)
        ORDER BY start_at DESC
        LIMIT 1;
        """

        if let record = fetchSingleSegment(sql: coveringSQL, binder: { statement in
            sqlite3_bind_double(statement, 1, timestamp)
            sqlite3_bind_double(statement, 2, timestamp)
        }) {
            return record
        }

        let nearestSQL = """
        SELECT file_name, start_at, end_at, size_bytes
        FROM segments
        WHERE start_at <= ?
        ORDER BY start_at DESC
        LIMIT 1;
        """

        return fetchSingleSegment(sql: nearestSQL, binder: { statement in
            sqlite3_bind_double(statement, 1, timestamp)
        })
    }

    func deleteSegment(fileName: String) {
        let sql = "DELETE FROM segments WHERE file_name = ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        bindText(statement, index: 1, value: fileName)
        sqlite3_step(statement)
    }

    func clearSegments() {
        execute(sql: "DELETE FROM segments;")
    }

    @discardableResult
    func addMarker(at timestamp: Date, note: String?) -> Int64? {
        let sql = "INSERT INTO markers (timestamp, note) VALUES (?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, timestamp.timeIntervalSince1970)
        if let note, !note.isEmpty {
            bindText(statement, index: 2, value: note)
        } else {
            sqlite3_bind_null(statement, 2)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else { return nil }
        return sqlite3_last_insert_rowid(db)
    }

    func fetchMarkers(from: Date? = nil, to: Date? = nil, limit: Int = 200) -> [MarkerRecord] {
        var conditions: [String] = []
        if from != nil { conditions.append("timestamp >= ?") }
        if to != nil { conditions.append("timestamp <= ?") }

        var sql = "SELECT id, timestamp, note FROM markers"
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }
        sql += " ORDER BY timestamp DESC LIMIT ?;"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        var bindIndex: Int32 = 1
        if let from {
            sqlite3_bind_double(statement, bindIndex, from.timeIntervalSince1970)
            bindIndex += 1
        }
        if let to {
            sqlite3_bind_double(statement, bindIndex, to.timeIntervalSince1970)
            bindIndex += 1
        }
        sqlite3_bind_int(statement, bindIndex, Int32(limit))

        var markers: [MarkerRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let note: String?
            if let cNote = sqlite3_column_text(statement, 2) {
                note = String(cString: cNote)
            } else {
                note = nil
            }
            markers.append(MarkerRecord(id: id, timestamp: timestamp, note: note))
        }
        return markers
    }

    private func openDatabase() {
        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            print("Cannot open SQLite database at \(databaseURL.path)")
        }
    }

    private func createSchemaIfNeeded() {
        execute(sql: """
        CREATE TABLE IF NOT EXISTS segments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_name TEXT NOT NULL UNIQUE,
            start_at REAL NOT NULL,
            end_at REAL,
            size_bytes INTEGER NOT NULL DEFAULT 0
        );
        """)

        execute(sql: "CREATE INDEX IF NOT EXISTS idx_segments_start_at ON segments(start_at);")
        execute(sql: "CREATE INDEX IF NOT EXISTS idx_segments_end_at ON segments(end_at);")

        execute(sql: """
        CREATE TABLE IF NOT EXISTS markers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            note TEXT
        );
        """)
        execute(sql: "CREATE INDEX IF NOT EXISTS idx_markers_timestamp ON markers(timestamp);")
    }

    private func execute(sql: String) {
        var errorMessage: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let errorMessage {
                let error = String(cString: errorMessage)
                print("SQLite error: \(error)")
                sqlite3_free(errorMessage)
            }
        }
    }

    private func fetchSingleSegment(sql: String, binder: (OpaquePointer?) -> Void) -> Record? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        binder(statement)

        guard sqlite3_step(statement) == SQLITE_ROW, let cName = sqlite3_column_text(statement, 0) else {
            return nil
        }

        let fileName = String(cString: cName)
        let startAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))

        var endDate: Date?
        if sqlite3_column_type(statement, 2) != SQLITE_NULL {
            endDate = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
        }

        let size = sqlite3_column_int64(statement, 3)
        return Record(title: fileName, date: startAt, endDate: endDate, sizeBytes: size)
    }

    private func bindText(_ statement: OpaquePointer?, index: Int32, value: String) {
        _ = value.withCString { cString in
            sqlite3_bind_text(statement, index, cString, -1, SQLITE_TRANSIENT)
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
