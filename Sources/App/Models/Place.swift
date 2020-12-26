//  Created by Alexander Skorulis on 18/11/20.

import Vapor
import Fluent

///A yahoo place mapped by a woeid
public final class Place: Model, Content {
    
    public static let schema = "place"
    
    @ID(custom: .id, generatedBy: .user)
    public var id: Int32?

    @Field(key: .name)
    public var name: String
    
    @Field(key: .updatedAt)
    var lastUpdate: Double
    
    @OptionalParent(key: .countryId)
    var country: Country?

    public init() { }

    public init(name: String, woeid: Int32, country: Country?) {
        self.name = name
        self.id = woeid
        self.lastUpdate = Date().timeIntervalSince1970
        self.$country.id = country?.id
    }
       
}

///Migration information for `Place`
public struct PlaceMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Place.schema)
            .field(.id, .int32, .identifier(auto: false))
            .field(.name, .string, .required)
            .field(.updatedAt, .double)
            .field(.countryId, .uuid, .references(Country.schema, .id))
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Place.schema).delete()
    }
    
    public init() {}
    
}

public struct PlaceDAO {
    
    func find(ids: [Int32]?, on db: Database) -> EventLoopFuture<[Place]> {
        var query = Place.query(on: db)
        if let ids = ids {
            query = query.filter(\.$id ~~ ids)
        }
        return query.all()
    }
    
}
