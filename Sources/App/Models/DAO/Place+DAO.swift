//  Created by Alexander Skorulis on 30/12/20.

import Foundation
import Fluent
import Vapor

extension Place {
    struct DAO {
        
        func find(ids: [Int32]?, on db: Database) -> EventLoopFuture<[Place]> {
            var query = Place.query(on: db)
            if let ids = ids {
                query = query.filter(\.$id ~~ ids)
            }
            return query.all()
        }
        
        public static func findCountry(code: String, in db: Database) -> EventLoopFuture<Place> {
            return Place.query(on: db).filter(\.$countryCode == code).first().flatMapThrowing { (optCountry) -> Place in
                guard let country = optCountry else {
                    throw Abort(.notFound, reason: "No country with code \(code)")
                }
                return country
            }
        }
        
        static func updateCountries(places: [TwitterPlace], on db: Database) -> EventLoopFuture<[Place]> {
            let countryPlaces = places.filter { $0.placeType.code == 12 }
            let countryIds = countryPlaces.map { $0.woeid }
            return Place.query(on: db).filter(\.$id ~~ countryIds).all().flatMap { (existingPlaces) -> EventLoopFuture<[Place]> in
                let existingPlaceIds = Set(existingPlaces.map { $0.id! })
                let missingPlaces = countryPlaces.filter { !existingPlaceIds.contains($0.woeid) }
                let toInsert = missingPlaces.map { (place) -> Place in
                    return Place(name: place.name, woeid: place.woeid, countryCode: place.countryCode, country: nil)
                }
                return toInsert.insertAll(on: db).map { (created) -> ([Place]) in
                    return existingPlaces + created
                }
            }
        }
    }
}
