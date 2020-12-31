//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import Fluent
import FluentSQL

extension GoogleDataPoint {
    struct DAO {
        
        ///Get the latest datapoints for each trend if they exist
        /*static func latest(items: [TrendItem], country: Country, db: Database) { //-> EventLoopFuture<GoogleDataPoint> {
            let itemIds = items.map { try! $0.requireID() }
            //TODO: Still under construction, not sure how to write the query to get the correct data
            //return GoogleDataPoint.query(on: db).filter(\.$trend.$id ~~ itemIds).filter(\.$country.$id == country.id!).all()
        }*/
        
        static func history(trend: TrendItem, timeframe: Double, in db: Database) -> EventLoopFuture<[GoogleDataPoint]> {
            let minTime = Date().timeIntervalSince1970 - timeframe
            return GoogleDataPoint.query(on: db)
                .filter(\.$trend.$id == trend.id!)
                .filter(\.$lastUpdate >= minTime)
                .sort(\.$lastUpdate).all()
        }
        
        static func topTrends(in db: Database, timeframe: Double = 24 * 60 * 60, placeId: Int?) -> EventLoopFuture<[TopTrendModel]> {
            guard let sql = db as? SQLDatabase else {
                return db.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Why no SQL"))
            }
            let time = Date().timeIntervalSince1970 - timeframe
            
            var select = sql.select()
                .column(SQLAlias(SQLColumn("trend_id", table: GoogleDataPoint.schema), as: SQLIdentifier("id")))
                .column(table: "trend", column: "key")
                .column(table: "trend", column: "display")
                .column(SQLAlias(SQLFunction("SUM", args: "value"), as: SQLIdentifier("value")))
                .from(GoogleDataPoint.schema)
                .join("trend", on: "trend.id = \(GoogleDataPoint.schema).trend_id")
                .where(SQLColumn("updated_at", table: GoogleDataPoint.schema), .greaterThanOrEqual, SQLBind(time))
                .groupBy("trend_id")
                .groupBy("key")
                .groupBy("display")
                .orderBy(SQLFunction("SUM",args:"value"), SQLDirection.descending)
                .limit(100)
            
            if let placeId = placeId {
                select = select.where(SQLColumn("country_id", table: GoogleDataPoint.schema), .equal, SQLBind(placeId))
            }
            
            return select.all().flatMapThrowing { (rows) -> [TopTrendModel] in
                return try rows.map { try TopTrendModel.fromRow(row: $0)}
            }
            
        }
    }
}
