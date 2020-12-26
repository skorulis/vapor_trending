//  Created by Alexander Skorulis on 18/11/20.

import Vapor
import Fluent

final class RedditTrend: Model, Content {
    static let schema = "reddit_trend"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?

    init() { }

}

public struct RedditTrendMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(RedditTrend.schema)
            .id()
            .field(.name, .string, .required)
            .field(.createdAt, .date)
            .field(.updatedAt, .date)
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(RedditTrend.schema).delete()
    }
    
    public init() {}
    
}
