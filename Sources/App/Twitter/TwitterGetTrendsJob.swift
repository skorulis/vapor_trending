//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 19/11/20.
//

import Vapor
import Queues
import Fluent

struct TwitterGetTrendsJob: ScheduledJob {
 
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        let future = context.application.db.transaction { (db) -> EventLoopFuture<Void> in
            return Place.query(on: db).sort(\.$lastUpdate).first().flatMap { (place) -> EventLoopFuture<Void> in
                guard let place = place else {
                    return db.eventLoop.makeSucceededFuture(Void())
                }
                return updatePlace(place: place, app: context.application, in: db)
            }
        }
        
        future.whenComplete { (result) in
            switch result {
            case .success(_):
                print("Finish job")
            case .failure(let error):
                print("Job failure \(error)")
            }
        }
        
        return future
    }
    
    private func updatePlace(place: Place, app: Application, in db: Database) -> EventLoopFuture<Void> {
        print("Getting twitter trends for \(place.name)")
        let client = app.client.twitterClient
        return client.getTrends(woeid: place.id!).flatMap { (trends) -> EventLoopFuture<Void> in
            return TwitterDataPointDAO().insert(place: place, points: trends, in: db).flatMap { (points) -> EventLoopFuture<Void> in
                place.lastUpdate = Date().timeIntervalSince1970
                return place.save(on: db)
            }
        }
    }
    
    
}
