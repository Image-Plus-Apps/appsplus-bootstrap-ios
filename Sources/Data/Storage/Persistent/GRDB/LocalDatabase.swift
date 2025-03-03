#if canImport(Foundation)
import Foundation
import GRDB

public protocol LocalDatabase {
    var database: DatabasePool { get }
}

public protocol DatabaseMigration {
    var name: String { get }
    func migrate(_ db: Database) throws
}

public struct LocalDatabaseImpl {

    public let database: DatabasePool
    private let migrations: [DatabaseMigration]
    
    public init(fileManager: FileManager = .default, migrations: [DatabaseMigration], enforceSchemaInDebug: Bool = false) {
        do {
            // Get the Application Support directory
            let folderURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            // Ensure the directory exists
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // Define the database file URL
            let dbURL = folderURL.appendingPathComponent("database.sqlite")
            
            // Check if the database file exists
            if !fileManager.fileExists(atPath: dbURL.path) {
                print("Database file does not exist. Creating it.\n")
            } else {
                print("Database file already exists at \(dbURL.path).\n")
            }
            
            // Initialise the database pool
            self.migrations = migrations
            database = try DatabasePool(path: dbURL.path)
            print("Database successfully read at \(dbURL.path), proceeding to migration.")
            
            
            // Set up the migrator
            var migrator = DatabaseMigrator()
            
            #if DEBUG
            if !enforceSchemaInDebug {
                print("""
                              
                              
                              
                              
                    *************************************************************************
                    *************************************************************************
                    ** DEBUG MODE ACTIVE, DATABASE WILL ERASE IF THE SCHEMA MISMATCHES !!! **
                    *************************************************************************
                    *************************************************************************
                              
                              
                    
                              
                    """)
                migrator.eraseDatabaseOnSchemaChange = true
            }
            #endif
            
            // get applies migrations
            let appliedMigrations = try database.read { db in
                try migrator.appliedIdentifiers(db)
            }
            
            // Register migrations
            for migration in migrations {
                migrator.registerMigration(migration.name) { db in
                    if !appliedMigrations.contains(migration.name) {
                        print("Applying migration: \"\(migration.name)\"\n")
                    }
                    try migration.migrate(db)
                }
            }
            
            // Apply migrations
            try migrator.migrate(database)
            print("Database successfully migrated!\n")
                
        } catch {
            fatalError("ERROR: \(error)")
        }
        
    }

}
#endif
