//
//  BookRecord.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import GRDB
import DifferenceKit


struct BookRecord: Equatable, Codable, Hashable, Differentiable, FetchableRecord, MutablePersistableRecord {
    var id: Int
    var version: BibleVersion
    var name: String

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let version = Column(CodingKeys.version)
        static let name = Column(CodingKeys.name)
    }
    
    static var databaseTableName: String = "books"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: "books") { t in
            t.column("id", .integer).notNull().primaryKey()
            t.column("version", .integer).notNull()
            t.column("name", .text).notNull()
        }
    }
}


struct BookNameRecord: Hashable, FetchableRecord {
    init(row: Row) throws {
        self.book = row["name"]
    }
    
    var book: String
}
