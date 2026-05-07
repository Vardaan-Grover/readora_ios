import Foundation
import GRDB

public protocol VocabularyRepository: Actor {
    func listSavedWords() async -> [SavedWord]
    func addSavedWord(_ word: SavedWord) async
    func removeSavedWord(id: UUID) async
    func getSavedWord(word: String, language: String) async -> SavedWord?
}

public final actor VocabularyRepositorySQLite: VocabularyRepository {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func listSavedWords() async -> [SavedWord] {
        await withCheckedContinuation { continuation in
            do {
                let items = try dbQueue.read { db in
                    try SavedWord.order(Column("createdAt").desc).fetchAll(db)
                }
                continuation.resume(returning: items)
            } catch {
                AppLogger.log(tag: "VocabularyRepository", "Error listing saved words: \(error)")
                continuation.resume(returning: [])
            }
        }
    }

    public func addSavedWord(_ word: SavedWord) async {
        await withCheckedContinuation { continuation in
            do {
                try dbQueue.write { db in
                    try word.insert(db)
                }
                continuation.resume()
            } catch {
                AppLogger.log(tag: "VocabularyRepository", "Error adding saved word: \(error)")
                continuation.resume()
            }
        }
    }

    public func removeSavedWord(id: UUID) async {
        await withCheckedContinuation { continuation in
            do {
                try dbQueue.write { db in
                    _ = try SavedWord.deleteOne(db, id: id)
                }
                continuation.resume()
            } catch {
                AppLogger.log(tag: "VocabularyRepository", "Error removing saved word: \(error)")
                continuation.resume()
            }
        }
    }

    public func getSavedWord(word: String, language: String) async -> SavedWord? {
        await withCheckedContinuation { continuation in
            do {
                let saved = try dbQueue.read { db in
                    try SavedWord.filter(Column("word") == word && Column("language") == language)
                        .fetchOne(db)
                }
                continuation.resume(returning: saved)
            } catch {
                AppLogger.log(tag: "VocabularyRepository", "Error fetching saved word: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
}
