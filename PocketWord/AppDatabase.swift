//
//  AppDatabase.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import GRDB
import Foundation
import OSLog





public struct AppDatabase {
    static let shared = AppDatabase()
    
    var database = makeDatabase()
    
    public var reader: DatabaseReader {
        database
    }
    

    /// Returns an on-disk database for the application.
    static func makeDatabase() -> DatabaseWriter {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("pocketword_db.sqlite")

            
            var migrator = DatabaseMigrator()
            
            migrator.eraseDatabaseOnSchemaChange = true
            migrator.registerMigration("createTables") { db in
                try BookRecord.createTable(db)
                try VerseRecord.createTable(db)
                try VerseRecord.createFTSTable(db)
            }
            
            let dbPool = try DatabasePool(
                path: databaseURL.path,
                configuration: makeConfiguration())
            
            try migrator.migrate(dbPool)
            
            return dbPool
            
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
    public static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base

        // An opportunity to add required custom SQL functions or
        // collations, if needed:
        // config.prepareDatabase { db in
        //     db.add(function: ...)
        // }
        
        // Log SQL statements if the `SQL_TRACE` environment variable is set.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/database/trace(options:_:)>
        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace { _ in
                    // It's ok to log statements publicly. Sensitive
                    // information (statement arguments) are not logged
                    // unless config.publicStatementArguments is set
                    // (see below).
//                    Logger.SQL.debug("\(String(describing: $0))")
                }
            }
        }
        
#if DEBUG
        // Protect sensitive information by enabling verbose debugging in
        // DEBUG builds only.
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/configuration/publicstatementarguments>
        config.publicStatementArguments = true
#endif
        
        return config
    }
}

