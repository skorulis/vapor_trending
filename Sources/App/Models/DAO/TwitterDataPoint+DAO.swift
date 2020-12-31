//  Created by Alexander Skorulis on 31/12/20.

import Vapor
import Fluent
import FluentSQL

extension TwitterDataPoint {
    
    struct DAO {
        
        static func topTrends(in db: Database, timeframe: Double = 24 * 60 * 60, placeId: Int?) -> EventLoopFuture<[TopTrendModel]> {
            guard let sql = db as? SQLDatabase else {
                return db.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Why no SQL"))
            }
            let time = Date().timeIntervalSince1970 - timeframe
            
            var select = sql.select()
                .column(SQLAlias(SQLColumn("trend_id", table: "twitter_data_point"), as: SQLIdentifier("id")))
                .column(table: "trend", column: "key")
                .column(table: "trend", column: "display")
                .column(SQLAlias(SQLFunction("SUM", args: "value"), as: SQLIdentifier("value")))
                .from("twitter_data_point")
                .join("trend", on: "trend.id = twitter_data_point.trend_id")
                .where(SQLColumn("created_at", table: "twitter_data_point"), .greaterThanOrEqual, SQLBind(time))
                .groupBy("trend_id")
                .groupBy("key")
                .groupBy("display")
                .orderBy(SQLFunction("SUM",args:"value"), SQLDirection.descending)
                .limit(100)
            
            if let placeId = placeId {
                select = select.where(SQLColumn("place_id", table: "twitter_data_point"), .equal, SQLBind(placeId))
            }
            return select.all().flatMapThrowing { (rows) -> [TopTrendModel] in
                return try rows.map { try TopTrendModel.fromRow(row: $0)}
            }
        }
        
        static func history(trend:TrendItem, timeframe: Double, in db: Database) -> EventLoopFuture<[TwitterDataPoint]> {
            let time = Date().timeIntervalSince1970 - timeframe
            
            return trend.$twitterDataPoints.query(on: db).filter(\.$createdAt >= time).sort(\.$createdAt).all()
        }
    }
}
