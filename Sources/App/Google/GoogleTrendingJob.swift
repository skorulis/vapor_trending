//  Created by Alexander Skorulis on 22/12/20.

import Vapor
import Queues

struct GoogleTrendingJob: ScheduledJob {
    
    private struct Progress {
        let status: JobStatus
        let country: Country
        var trends: [TrendItem] = []
        var searches: [GoogleTrendingSearch] = []
        
        func with(trends: [TrendItem]) -> Progress {
            var copy = self
            copy.trends = trends
            return copy
        }
        
        func with(response: GoogleDailyTrendsResponse) -> Progress {
            var copy = self
            copy.searches = response.trendingSearchesDays.flatMap({ (day) -> [GoogleTrendingSearch] in
                return day.trendingSearches
            })
            return copy
        }
        
        var allTrends: [String] {
            return searches.map { $0.title.query }
        }
        
        func getTrend(title: String) -> TrendItem? {
            return trends.first { (trend) -> Bool in
                return trend.key == title.lowercased()
            }
        }
    }
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        let client = context.application.client.googleClient
        let trendDAO = TrendItemDAO()
        return context.application.db.transaction { (db) -> EventLoopFuture<Void> in
            let statusFuture:EventLoopFuture<JobStatus> = JobStatusDAO.get(type: .googleDaily, db: db).flatMapThrowing { (status) -> (JobStatus) in
                guard let status = status else {
                    throw Abort(.notFound, reason: "Job not yet ready")
                }
                return status
            }
            let countryFuture = statusFuture.flatMap { (status) -> EventLoopFuture<(Progress)> in
                guard let countryCode: String = status.jobData.google?.nextCountry else {
                    return db.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Incorrect job setup, no google country code"))
                }
                return CountryDAO.find(code: countryCode, in: db).map { (country) -> (Progress) in
                    return Progress(status: status, country: country)
                }
            }
            let apiFuture = countryFuture.flatMap { (progress) -> EventLoopFuture<Progress> in
                print("Getting google trends for \(progress.country.name) (\(progress.country.countryCode))")
                return client.getDailyTrends(countryCode: progress.country.countryCode).map { (response) -> (Progress) in
                    return progress.with(response: response)
                }
            }
            let trendFuture = apiFuture.flatMap { (progress) -> EventLoopFuture<Progress> in
                return trendDAO.findOrCreate(trends: progress.allTrends, in: db).map { (trendItems) -> (Progress) in
                    return progress.with(trends: trendItems)
                }
            }
            
            let dataFuture = trendFuture.flatMap { (progress) -> EventLoopFuture<Progress> in
                let createdItems = progress.searches.map { (search) -> GoogleDataPoint in
                    let trend = progress.getTrend(title: search.title.query)!
                    return try! GoogleDataPoint(value: search.trafficValue, trend: trend, country: progress.country)
                }
                return createdItems.insertAll(on: db).transform(to: progress)
            }
            
            return dataFuture.flatMap { (progress) -> EventLoopFuture<Void> in
                let status = progress.status
                status.jobData.google?.lastUpdates[progress.country.countryCode] = Date().timeIntervalSince1970
                return status.update(on: db).transform(to: Void())
            }
            
            
        }
    }
    
}
