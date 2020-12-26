//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 22/12/20.
//

import Vapor
import Fluent

final class GoogleDataPoint: Model, Content {
    
    public static let schema = "google_data_point"
    
    @ID(key: .id)
    ///Primary key
    public var id: UUID?
    
    @Field(key: .value)
    var value: Int
    
    @Field(key: .updatedAt)
    var lastUpdate: Double
    
    @Parent(key: .trendId)
    var trend: TrendItem
    
    @Parent(key: .countryId)
    var country: Country

    public init() { }

    public init(value: Int, trend: TrendItem, country: Country) throws {
        self.lastUpdate = Date().timeIntervalSince1970
        self.value = value
        self.$trend.id = try trend.requireID()
        self.$country.id = try country.requireID()
    }
    
}

struct GoogleDataPointMigration: Migration {
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(GoogleDataPoint.schema)
            .id()
            .field(.value, .int)
            .field(.updatedAt, .double)
            .field(.trendId, .uuid, .references(TrendItem.schema, .id))
            .field(.countryId, .uuid, .references(Country.schema, .id))
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(GoogleDataPoint.schema).delete()
    }
    
    public init() {}
    
    
}
