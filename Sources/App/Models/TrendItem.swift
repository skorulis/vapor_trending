//  Created by Alexander Skorulis on 18/11/20.

import Vapor
import Fluent

final class TrendItem: Model, Content {
    static let schema = "trend"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: .key)
    var key: String
    
    @Field(key: .display)
    var display: String
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Children(for: \.$trend)
    var twitterDataPoints: [TwitterDataPoint]

    init() { }

    init(key: String, display: String) {
        self.key = key
        self.display = display
    }
}

public struct TrendItemMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TrendItem.schema)
            .id()
            .field(.key, .string, .required)
            .field(.display, .string, .required)
            .field(.createdAt, .date)
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TrendItem.schema).delete()
    }
    
    public init() {}
    
}

public struct TrendItemDAO {
    
    func findOrCreate(trends: [String], in db: Database) -> EventLoopFuture<[TrendItem]> {
        let items:[(key:String, display: String)] = trends.map { (key: $0.lowercased(), display: $0) }
        let lowercased:[String] = items.map { $0.key }
        return TrendItem.query(on: db).filter(\.$key ~~ lowercased).all().flatMap { (existing) -> EventLoopFuture<[TrendItem]> in
            
            let foundKeys = Set(existing.map { $0.key })
            let missing = items.filter { !foundKeys.contains($0.key) }.map { TrendItem(key: $0.key, display: $0.display) }
            let createFutures:[EventLoopFuture<TrendItem>] = missing.map { $0.insert(on: db) }
            return createFutures.flatten(on: db.eventLoop).map { (created) -> ([TrendItem]) in
                return existing + created
            }
        }
    }
    
    func named(_ name: String, in db: Database) -> EventLoopFuture<TrendItem?> {
        return TrendItem.query(on: db).filter(\.$key == name.lowercased()).first()
    }
    
    func find(id: String, in db: Database) -> EventLoopFuture<TrendItem?> {
        guard let uuid = UUID(id) else {
            return db.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Invalid UUID: \(id)"))
        }
        return TrendItem.find(uuid, on: db)
    }
    
}
