//  Created by Alexander Skorulis on 27/11/20.

import Vapor

private struct StatsResponse: Content {
    let trendCount: Int
    let placeCount: Int
    let twitterPointCount: Int
}

struct StatsController: RegisteredRouteCollection {
    
    func boot(routes: RoutesBuilder, registry: RouteRegistry) throws {
        let group = routes.grouped("stats")
        
        group.get() { (req) -> EventLoopFuture<StatsResponse> in
            let trendCount = TrendItem.query(on: req.db).count()
            let placeCount = Place.query(on: req.db).count()
            let twitterCount = TwitterDataPoint.query(on: req.db).count()
            return [trendCount, placeCount, twitterCount].flatten(on: req.eventLoop).map { (counts) -> (StatsResponse) in
                return StatsResponse(trendCount: counts[0], placeCount: counts[1], twitterPointCount: counts[2])
            }
        }.register(as: "stats", in: registry)
        
    }
    
}

