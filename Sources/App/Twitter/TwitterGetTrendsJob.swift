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
 
    private struct Progress {
        let status: JobStatus
        let placeId: Int32
        var response: [TwitterTrend] = []
        
        func with(response: [TwitterTrend]) -> Progress {
            var temp = self
            temp.response = response
            return temp
        }
    }
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        let future = context.application.db.transaction { (db) -> EventLoopFuture<Void> in
            let statusFuture:EventLoopFuture<Progress> = JobStatusDAO.get(type: .twitter, db: db).flatMapThrowing { (status) -> (Progress) in
                guard let status = status else {
                    throw Abort(.notFound, reason: "Job not yet ready")
                }
                guard let placeCode: Int32 = status.jobData.twitter?.nextPlace else {
                    throw Abort(.notFound, reason: "Incorrect job setup, no twitter place ID")
                }
                return Progress(status: status, placeId: placeCode)
            }
            
            let apiFuture = statusFuture.flatMap { (progress) -> EventLoopFuture<Progress> in
                
                print("Getting twitter trends for \(progress.placeId)")
                let client = context.application.client.twitterClient
                return client.getTrends(woeid: progress.placeId).map { (trends) -> (Progress) in
                    return progress.with(response: trends)
                }
            }
            
            let dbFuture = apiFuture.flatMap { (progress) -> EventLoopFuture<Progress> in
                return TwitterDataPointDAO().insert(placeId: progress.placeId, points: progress.response, in: db).transform(to: progress)
            }
            
            return dbFuture.flatMap { (progress) -> EventLoopFuture<Void> in
                let status = progress.status
                status.jobData.twitter?.lastUpdates[progress.placeId] = Date().timeIntervalSince1970
                return status.update(on: db).transform(to: Void())
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
    
}
