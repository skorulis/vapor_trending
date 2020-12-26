//  Created by Alexander Skorulis on 21/11/20.

import Vapor

struct TrendDetails: Content {
    
    let trend: TrendItem
    let history: [TwitterDataPoint]
    
}

private struct TrendQuery: Decodable {
    let seconds: Double?
    let placeId: Int?
}

struct TrendController: RegisteredRouteCollection {
    func boot(routes: RoutesBuilder, registry: RouteRegistry) throws {
        
        let group = routes.grouped("trend")
        let queryExample = TrendQuery(seconds: 86400, placeId: 1)
        
        group.get("top") { (req) -> EventLoopFuture<[TopTrendModel]> in
            let params = try req.query.decode(TrendQuery.self)
            let timeframe = params.seconds ?? 86400
            return TwitterDataPointDAO().topTrends(in: req.db, timeframe: timeframe, placeId: params.placeId)
        }.register(as: "top_trends", in: registry, queryExample: queryExample)
        
        group.get(":name") { (req) -> EventLoopFuture<TrendDetails> in
            let name = req.parameters.get("name")!
            return TrendItemDAO().named(name, in: req.db).flatMap({ (trend) -> EventLoopFuture<TrendDetails> in
                guard let trend = trend else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Could not find trend \(name)"))
                }
                return TwitterDataPointDAO().history(trend: trend, timeframe: 86400, in: req.db).map { (history) -> (TrendDetails) in
                    return TrendDetails(trend: trend, history: history)
                }
                
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
                return TwitterDataPointDAO().history(trend: trend, timeframe: timeframe, in: req.db).map { (history) -> (TrendDetails) in
                    return TrendDetails(trend: trend, history: history)
                }
                
            })
        }.register(as: "trend_details_id", in: registry, queryExample: queryExample)
    }
    
}


