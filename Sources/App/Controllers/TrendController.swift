//  Created by Alexander Skorulis on 21/11/20.

import Vapor
import Fluent

struct TrendDetails: Content {
    
    let trend: TrendItem
    let twitterHistory: [TwitterDataPoint]
    let googleHistory: [GoogleDataPoint]
    
}

private struct TrendQuery: Decodable {
    let seconds: Double?
    let placeId: Int?
}

struct TopTrendsResponse: Content {
    
    let twitter: [TopTrendModel]
    let google: [TopTrendModel]
    
}

struct TrendController: RegisteredRouteCollection {
    
    func boot(routes: RoutesBuilder, registry: RouteRegistry) throws {
        
        let group = routes.grouped("trend")
        let queryExample = TrendQuery(seconds: 86400, placeId: 1)
        
        group.get("top") { (req) -> EventLoopFuture<TopTrendsResponse> in
            let params = try req.query.decode(TrendQuery.self)
            let timeframe = params.seconds ?? 86400
            let twitterTrends = TwitterDataPoint.DAO.topTrends(in: req.db, timeframe: timeframe, placeId: params.placeId)
            let googleTrends = GoogleDataPoint.DAO.topTrends(in: req.db, timeframe: timeframe, placeId: params.placeId)
            return twitterTrends.and(googleTrends).map { (twitter,google) -> (TopTrendsResponse) in
                return TopTrendsResponse(twitter: twitter, google: google)
            }
        }.register(as: "top_trends", in: registry, queryExample: queryExample)
        
        group.get(":name") { (req) -> EventLoopFuture<TrendDetails> in
            let name = req.parameters.get("name")!
            return TrendItemDAO().named(name, in: req.db).flatMap({ (trend) -> EventLoopFuture<TrendDetails> in
                guard let trend = trend else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Could not find trend \(name)"))
                }
                let timeframe: Double = 86400
                return getHistory(trend: trend, timeframe: timeframe, on: req.db)
            })
        }.register(as: "trend_details", in: registry)
        
        group.get("id",":id") { (req) -> EventLoopFuture<TrendDetails> in
            guard let id = req.parameters.get("id") else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound))
            }
            let params = try req.query.decode(TrendQuery.self)
            let timeframe = params.seconds ?? 86400
            
            return TrendItemDAO().find(id:id, in: req.db).flatMap({ (trend) -> EventLoopFuture<TrendDetails> in
                guard let trend = trend else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Could not find trend \(id)"))
                }
                return getHistory(trend: trend, timeframe: timeframe, on: req.db)
            })
        }.register(as: "trend_details_id", in: registry, queryExample: queryExample)
    }
    
}

private extension TrendController {
    
    func getHistory(trend: TrendItem, timeframe: Double, on db: Database) -> EventLoopFuture<TrendDetails> {
        let twitterFuture = TwitterDataPoint.DAO.history(trend: trend, timeframe: timeframe, in: db)
        let googleFuture = GoogleDataPoint.DAO.history(trend: trend, timeframe: timeframe, in: db)
        return twitterFuture.and(googleFuture).map { (twitterHistory, googleHistory) -> (TrendDetails) in
            return TrendDetails(trend: trend, twitterHistory: twitterHistory, googleHistory: googleHistory)
        }
    }
    
}
