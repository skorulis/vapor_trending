//  Created by Alexander Skorulis on 19/11/20.

import Vapor
import Fluent
import FluentSQL

final class TwitterDataPoint: Model {
    
    static let schema = "twitter_data_point"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .createdAt)
    var createdAt: Double
    
    @Field(key: .value)
    var value: Int
    
    @Parent(key: .placeId)
    var place: Place
    
    @Parent(key: .trendId)
    var trend: TrendItem

    init() { }

    init(trend: TrendItem, place: Place, value: Int) throws {
        self.$trend.id = try trend.requireID()
        self.$place.id = try place.requireID()
        self.createdAt = Date().timeIntervalSince1970
        self.value = value
    }
    
}

struct TwitterDataPointMigration: Migration {
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwitterDataPoint.schema)
            .id()
            .field(.createdAt, .double)
            .field(.value, .int)
            .field(.placeId, .int32, .references(Place.schema, .id))
            .field(.trendId, .uuid, .references(TrendItem.schema, .id))
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwitterDataPoint.schema).delete()
    }
    
    public init() {}
    
    
}

struct TopTrendModel: Content {
    let id: String
    let key: String
    let display: String
    let value: Int
    
    init(id: String, key: String, display: String, value: Int) {
        self.id = id
        self.key = key
        self.display = display
        self.value = value
    }
}

struct TwitterDataPointDAO {
    
    func insert(place: Place, points: [TwitterTrend], in db: Database) -> EventLoopFuture<[TwitterDataPoint]> {
        let trendNames = Set(points.map { $0.name })
        return TrendItemDAO().findOrCreate(trends: Array(trendNames), in: db).flatMap { (items) -> EventLoopFuture<[TwitterDataPoint]> in
            let itemMap = Dictionary(grouping: items) { (trend) -> String in
                return trend.key
            }.mapValues { $0[0] }
            
            let dataPoints = points.map { (trend) -> TwitterDataPoint in
                let dbTrend = itemMap[trend.name.lowercased()]!
                return try! TwitterDataPoint(trend: dbTrend, place: place, value: trend.tweet_volume ?? 0)
            }
            
            return dataPoints.map { $0.insert(on: db)}.flatten(on: db.eventLoop)
        }
    }
    
    
    func topTrends(in db: Database, timeframe: Double = 24 * 60 * 60, placeId: Int?) -> EventLoopFuture<[TopTrendModel]> {
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
            return try rows.map({ (row) -> TopTrendModel in
                let id = try row.decode(column: "id", as: String.self)
                let key = try row.decode(column: "key", as: String.self)
                let display = try row.decode(column: "display", as: String.self)
                let value = try row.decodeInt(column: "value")
                return TopTrendModel(id: id, key: key, display: display, value: value)
            })
        }
    }
    
    func history(trend:TrendItem, timeframe: Double, in db: Database) -> EventLoopFuture<[TwitterDataPoint]> {
        let time = Date().timeIntervalSince1970 - timeframe
        
        return trend.$twitterDataPoints.query(on: db).filter(\.$createdAt >= time).sort(\.$createdAt).all()
    }
    
}

extension SQLRow {
    
    ///Decode an int despite the data type coming back from SQL
    func decodeInt(column: String) throws -> Int {
        if let intValue = try? self.decode(column: column, as: Int.self) {
            return intValue
        }
        let doubleValue = try self.decode(column: column, as: Double.self)
        return Int(doubleValue)
    }
    
}
