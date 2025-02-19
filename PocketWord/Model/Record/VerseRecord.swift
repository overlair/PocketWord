//
//  VerseRecord.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import Foundation
import GRDB
import DifferenceKit


// Data
struct VerseRecord: Equatable, Codable, Hashable, Differentiable, FetchableRecord, MutablePersistableRecord {
    var id: Int
    var version: BibleVersion
    var book: Int
    var chapter: Int
    var verse: Int
    var text: String
 
    // Define database columns from CodingKeys
    enum Columns {
        
        static let id = Column(CodingKeys.id)
        static let version = Column(CodingKeys.version)
        static let book = Column(CodingKeys.book)
        static let chapter = Column(CodingKeys.chapter)
        static let verse = Column(CodingKeys.verse)
        static let text = Column(CodingKeys.text)
    }
    
    static var databaseTableName: String = "verses"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: "verses") { t in
            t.column("id", .integer).notNull().primaryKey()
            t.column("version", .integer).notNull().indexed()
            t.column("book", .integer).notNull().indexed()
            t.column("chapter", .integer).notNull().indexed()
            t.column("verse", .integer).notNull().indexed()
            t.column("text", .text).notNull()
        }
    }
    
    static func createFTSTable(_ db: Database) throws {
        try db.create(virtualTable: "verses_ft", using: FTS4()) { t in
            t.tokenizer = .unicode61()
            // See https://github.com/groue/GRDB.swift#external-content-full-text-tables
            t.synchronize(withTable: "verses")
            t.column("text")
            
        }
    }
    
}


struct VerseTextRecord: Hashable, FetchableRecord {
    init(row: Row) throws {
        self.verse = row["verse"]
        self.text = row["text"]
    }
    
    var verse: Int
    var text: String
}


struct VerseNamedRecord: Hashable, FetchableRecord {
    init(row: Row) throws {
        self.book = row["book"]
        self.bookName = row["bookName"]
        self.chapter = row["chapter"]
        self.verse = row["verse"]
        self.text = row["text"]
    }
    
    var book: Int
    var bookName: String
    var chapter: Int
    var verse: Int
    var text: String
}


