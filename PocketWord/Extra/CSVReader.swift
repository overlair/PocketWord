//
//  CSVReader.swift
//  PocketWord
//
//  Created by John Knowles on 2/14/25.
//

import Foundation
import SwiftCSV


func readCSV(version: BibleVersion = .kjv) {
    
    /*
        ignore the first row
     
        var
     */
    
    var books: [BookRecord] = []
    var currentBook = String?.none
    var verses: [VerseRecord] = []
    var bookCounter  = 0
    //locate the file you want to use
    guard let filepath = Bundle.main.url(forResource: "AKJV", withExtension: "csv") else {
            return
        }
        do {
            let csvFile: CSV = try CSV<Named>(url:  filepath)
            
            try csvFile.enumerateAsDict { dict in
                let name = dict["Book"] ?? ""
                let chapter = Int(dict["Chapter"] ?? "1") ?? 1
                let verse = Int(dict["Verse"] ?? "1") ?? 1
                let rawText = dict["Text"] ?? ""
                let isParagraphEnd = rawText.contains("¶")
                var text = rawText
                    .replacingOccurrences(of: "¶", with: "")
                    .trailingSpacesTrimmed
                    .drop(while: { c in c.isWhitespace })

                if isParagraphEnd {
                    text = text + "\n"
                }
                if currentBook != name {
                    bookCounter += 1

                    currentBook = name
                    let id = (version.rawValue * 1000) + bookCounter
                    books.append(BookRecord(id: id, version: .kjv, name: name))
                }
                
                let id = version.rawValue * 1000000000 + bookCounter * 1000000 + chapter * 1000 + verse
                let record = VerseRecord(id: id, version: version, book: bookCounter, chapter: chapter, verse: verse , text: String(text))
                verses.append(record)
            }
            
            try AppDatabase.shared.database.write { db in
                try verses.forEach { record in
                    try record.inserted(db, onConflict: .replace)
                }
                try books.forEach { record in
                    try record.inserted(db, onConflict: .replace)
                }
            }
            
        } catch let parseError as CSVParseError {
            // Catch errors from parsing invalid CSV
        } catch {
            // Catch errors from trying to load files
        }
        //convert that file into one long string
//        var data = ""
//        do {
//            data = try String(contentsOfFile: filepath)
//        } catch {
//            print(error)
//            return
//        }
//
//        //now split that string into an array of "rows" of data.  Each row is a string.
//        var rows = data.components(separatedBy: "\n")
//
//        //if you have a header row, remove it here
//        rows.removeFirst()
//
//        //now loop around each row, and split it into each of its columns
//        for row in rows {
//            let columns = row.components(separatedBy: ",")
//
//            //check that we have enough columns
//            if columns.count == 4 {
//                let name = columns[0]
//                let chapter = Int(columns[1]) ?? 0
//                let verse = Int(columns[2]) ?? 0
//                let text = columns[3]
//
//                let version = 0
//
//                if currentBook != name {
//                    currentBook = name
//                    let id = version * 1000 + bookCounter
//                    books.append(BookRecord(id: id, version: version, name: name))
//                    bookCounter += 1
//                }
//                
//                let id = version * 1000000000 + bookCounter * 1000000 + chapter * 1000 + verse
//                let record = VerseRecord(id: id, version: version, book: bookCounter, chapter: chapter, verse: verse , text: text)
//                verses.append(record)
//            }
//        }
    
//    do {
//        try AppDatabase.shared.database.write { db in
//            try verses.forEach { record in
//                try record.inserted(db, onConflict: .replace)
//            }
//            try books.forEach { record in
//                try record.inserted(db, onConflict: .replace)
//            }
//        }
//        
//    } catch {
//        
//        print(error)
//    }

    
}

extension String {
    var trailingSpacesTrimmed: String {
        var newString = self

        while newString.last == " " {
            newString = String(newString.dropLast())
        }

        return newString
    }
}
