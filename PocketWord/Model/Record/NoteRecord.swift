//
//  NoteRecord.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//

import Foundation
import GRDB
import DifferenceKit


struct NoteRecord: Codable, Hashable, Differentiable, FetchableRecord, MutablePersistableRecord {
    var id: UUID
    var version: BibleVersion
    var book: Int
    var chapter: Int
    var startVerse: Int
    var endVerse: Int
    var startOffset: Int
    var endOffset: Int
    var note: String
    var isFavorite: Bool

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let version = Column(CodingKeys.version)
        static let book = Column(CodingKeys.book)
        static let chapter = Column(CodingKeys.chapter)
        static let startVerse = Column(CodingKeys.startVerse)
        static let endVerse = Column(CodingKeys.endVerse)
        static let startOffset = Column(CodingKeys.startOffset)
        static let endOffset = Column(CodingKeys.endOffset)
        static let note = Column(CodingKeys.note)
        static let isFavorite = Column(CodingKeys.isFavorite)
    }
    
    static var databaseTableName: String = "notes"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: "notes") { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("version", .integer).notNull()
            t.column("book", .integer).notNull()
            t.column("chapter", .integer).notNull()
            t.column("startVerse", .integer).notNull()
            t.column("endVerse", .integer).notNull()
            t.column("startOffset", .integer).notNull()
            t.column("endOffset", .integer).notNull()
            t.column("note", .text).notNull()
            t.column("isFavorite", .boolean).notNull()
        }
    }
    
    static func createFTSTable(_ db: Database) throws {
        try db.create(virtualTable: "notes_ft", using: FTS4()) { t in
            t.tokenizer = .unicode61()
            // See https://github.com/groue/GRDB.swift#external-content-full-text-tables
            t.synchronize(withTable: "notes")
            t.column("note")
            
        }
    }
}
