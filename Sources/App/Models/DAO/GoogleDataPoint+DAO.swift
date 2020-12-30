//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import Fluent

extension GoogleDataPoint {
    struct DAO {
        
        ///Get the latest datapoints for each trend if they exist
        /*static func latest(items: [TrendItem], country: Country, db: Database) { //-> EventLoopFuture<GoogleDataPoint> {
            let itemIds = items.map { try! $0.requireID() }
            //TODO: Still under construction, not sure how to write the query to get the correct data
            //return GoogleDataPoint.query(on: db).filter(\.$trend.$id ~~ itemIds).filter(\.$country.$id == country.id!).all()
        }*/
        
        func history(trend: TrendItem, timeframe: Double, in db: Database) -> EventLoopFuture<[GoogleDataPoint]> {
            return db.eventLoop.makeSucceededFuture([])
        }
    }
}
