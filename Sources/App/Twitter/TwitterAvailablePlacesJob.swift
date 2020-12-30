//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 18/11/20.
//

import Foundation
import Queues
import Fluent

struct TwitterAvailablePlacesJob: ScheduledJob {
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        
        return context.application.client.twitterClient.getAvailablePlaces().flatMap { (places) -> EventLoopFuture<Void> in
            return context.application.db.transaction { (db) -> EventLoopFuture<Void> in
                print("Saving twitter places")
                
                return Place.DAO.updateCountries(places: places, on: db).flatMap { (countries) -> EventLoopFuture<Void> in
                    return self.save(places: places, countries: countries, db: db)
                }
            }   
        }
    }
    
    private func save(places: [TwitterPlace], countries: [Place], db: Database) -> EventLoopFuture<Void> {
        let countryMap = Dictionary(grouping: countries) { (country) -> String in
            return country.countryCode!
        }.mapValues { $0[0] }
        let woeids = places.map { $0.woeid }
        return Place.query(on: db).filter(\.$id ~~ woeids).all().flatMap { (existing) -> EventLoopFuture<Void> in
            let foundWoeids = Set(existing.map { $0.id! })
            let missing = places.filter { !foundWoeids.contains($0.woeid) }
            let placeItems = missing.map { (place) -> Place in
                var country: Place?
                if let code = place.countryCode {
                    country = countryMap[code]
                }
                return Place(name: place.name, woeid: place.woeid, countryCode: nil , country: country)
            }
            return placeItems.insertAll(on: db).flatMap { (_) -> EventLoopFuture<Void> in
                return updateJobStatuses(places: places, db: db)
            }
        }
        
    }
    
    private func updateGoogleJob(places: [TwitterPlace], db: Database) -> EventLoopFuture<Void> {
        return JobStatusDAO.get(type: .googleDaily, db: db).flatMap { (job) -> EventLoopFuture<Void> in
            if let job = job {
                job.jobData.google?.update(places: places)
                return job.update(on: db).transform(to: Void())
            } else {
                let job = JobStatus(google: GoogleJobData(places: places))
                return job.create(on: db).transform(to: Void())
            }
        }
    }
    
    private func updateTwitterJob(places: [TwitterPlace], db: Database) -> EventLoopFuture<Void> {
        return JobStatusDAO.get(type: .twitter, db: db).flatMap { (job) -> EventLoopFuture<Void> in
            if let job = job {
                job.jobData.twitter?.update(places: places)
                return job.update(on: db).transform(to: Void())
            } else {
                let job = JobStatus(twitter: TwitterJobData(places: places))
                return job.create(on: db).transform(to: Void())
            }
        }
    }
    
    private func updateJobStatuses(places: [TwitterPlace], db: Database) -> EventLoopFuture<Void> {
        let f1 = updateGoogleJob(places: places, db: db)
        let f2 = updateTwitterJob(places: places, db: db)
        return f1.and(f2).transform(to: Void())
    }
    
    /*private func uniqueCountries(places: [TwitterPlace]) -> [Country] {
        var codeMapping: [String: Country] = [:]
        for place in places {
            if let code = place.countryCode, codeMapping[code] == nil {
                codeMapping[code] = Country(name: place.country, countryCode: code)
            }
        }
        return Array(codeMapping.values)
    }*/
    
    
}
