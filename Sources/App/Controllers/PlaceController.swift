//  Created by Alexander Skorulis on 26/11/20.

import Vapor

private struct PlaceQuery: Content {
    var ids: String?
}

struct PlaceController: RegisteredRouteCollection {
    
    func boot(routes: RoutesBuilder, registry: RouteRegistry) throws {
        let group = routes.grouped("place")
        
        let queryExample = PlaceQuery(ids: "88c858a3-b622-428b-b5b4-168773631fad,3e868928-f921-4ad2-9f6b-68d9106b0999")
        group.get() { (req) -> EventLoopFuture<[Place]> in
            let params = try req.query.decode(PlaceQuery.self)
            let woeids = try params.ids?.split(separator: ",").map { (id) -> Int32 in
                guard let uuid = Int32(String(id)) else {
                    throw Abort(.badRequest, reason: "\(id) is not an Int")
                }
                return uuid
            }
            
            return PlaceDAO().find(ids: woeids, on: req.db)
        }.register(as: "places", in: registry, queryExample: queryExample)
        
    }
    
}
