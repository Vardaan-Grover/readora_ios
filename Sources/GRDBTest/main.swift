import Foundation
import GRDB

struct Book: Identifiable, Equatable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName: String = "books"
    
    // Test if this GRDB feature exists
    static var databaseUUIDEncodingStrategy: DatabaseUUIDEncodingStrategy {
        return .uppercaseString
    }

    let id: UUID
    let title: String
}

let dbQueue = try! DatabaseQueue()
try! dbQueue.write { db in
    try db.create(table: "books") { t in
        t.column("id", .text).notNull().primaryKey()
        t.column("title", .text).notNull()
    }

    let book = Book(id: UUID(uuidString: "53ea596e-b8a9-4b2c-84a8-266d9a4c14d0")!, title: "test title")
    try book.insert(db)

    let rows = try Row.fetchAll(db, sql: "SELECT id FROM books")
    for row in rows {
        let dbValue: DatabaseValue = row["id"]
        print("Inserted ID in DB is: \(dbValue) (type: \(type(of: dbValue)))")
        let str: String = row["id"]
        print("As string: \(str)")
    }
}
