//  Created by Alexander Skorulis on 18/11/20.
//

import Vapor
import Fluent

///A country
public final class Country: Model, Content {
    public static let schema = "country"
    
    @ID(key: .id)
    ///Primary key
    public var id: UUID?

    @Field(key: .name)
    ///Display name
    public var name: String
    
    
    @Field(key: .countryCode)
    ///Short code
    public var countryCode: String
    
    public init() { }

    public init(name: String, countryCode: String) {
        self.name = name
        self.countryCode = countryCode
    }
}

///Migration object for `Country`
public struct CountryMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Country.schema)
            .id()
            .field(.name, .string, .required)
            .field(.countryCode, .string, .required)
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Country.schema).delete()
    }
    
    public init() {}
    
}

public struct CountryDAO {
    
    public func insertMissing(countries: [Country], in db: Database) -> EventLoopFuture<[Country]> {
        let codes: [String] = countries.map { $0.countryCode }
        return Country.query(on: db).filter(\.$countryCode ~~ codes).all().flatMap { (existing) -> EventLoopFuture<[Country]> in
            let foundCodes = Set(existing.map { $0.countryCode })
            let missing:[Country] = countries.filter { !foundCodes.contains($0.countryCode) }
            return missing.map { $0.insert(on: db) }.flatten(on: db.eventLoop).map { (created) -> ([Country]) in
                return created + existing
            }
        }
    }
    
    public static func find(code: String, in db: Database) -> EventLoopFuture<Country> {
        return Country.query(on: db).filter(\.$countryCode == code).first().flatMapThrowing { (optCountry) -> Country in
            guard let country = optCountry else {
                throw Abort(.notFound, reason: "No country with code \(code)")
            }
            return country
        }
    }
}

