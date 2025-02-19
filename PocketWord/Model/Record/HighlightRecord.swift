//
//  HighlightRecord.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//

import Foundation
import GRDB
import DifferenceKit


struct HighlightRecord:  Codable, Hashable, Differentiable, FetchableRecord, MutablePersistableRecord {
    var id: UUID
    var version: BibleVersion
    var book: Int
    var chapter: Int
    var startVerse: Int
    var endVerse: Int
    var startOffset: Int
    var endOffset: Int
    var color: HighlightColor

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let version = Column(CodingKeys.version)
        static let book = Column(CodingKeys.book)
        static let chapter = Column(CodingKeys.chapter)
        static let startVerse = Column(CodingKeys.startVerse)
        static let endVerse = Column(CodingKeys.endVerse)
        static let startOffset = Column(CodingKeys.startOffset)
        static let endOffset = Column(CodingKeys.endOffset)
        static let color = Column(CodingKeys.color)
    }
    
    static var databaseTableName: String = "highlights"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: "highlights") { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("version", .integer).notNull()
            t.column("book", .integer).notNull()
            t.column("chapter", .integer).notNull()
            t.column("startVerse", .integer).notNull()
            t.column("endVerse", .integer).notNull()
            t.column("startOffset", .integer).notNull()
            t.column("endOffset", .integer).notNull()
            t.column("color", .integer).notNull()
        }
    }
}
