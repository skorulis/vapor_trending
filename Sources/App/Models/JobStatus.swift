//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import Fluent

enum JobStatusType: String, Codable {
    case twitter
    case googleDaily
}

struct TwitterJobData: Codable {
    
    ///Update time for woeid
    var lastUpdates: [Int32: TimeInterval] = [:]
    
    init(places: [TwitterPlace]) {
        update(places: places)
    }
    
    ///Update available places
    mutating func update(places: [TwitterPlace]) {
        places.forEach { (place) in
            if lastUpdates[place.woeid] == nil {
                lastUpdates[place.woeid] = 0
            }
        }
        
    }
    
    var nextPlace: Int32 {
        var best: Int32 = 1
        var bestValue: TimeInterval = Date().timeIntervalSince1970
        for (key,value) in lastUpdates {
            if value < bestValue {
                best = key
                bestValue = value
            }
        }
        return best
    }
    
}

struct GoogleJobData: Codable {
    
    ///Update time for country code
    var lastUpdates: [String: TimeInterval] = [:]
    
    private static let excludedCodes: Set<String> = ["AE", "BH", "BY", "DO", "DZ", "EC","ES", "GH", "GT","ID", "JO", "KW", "LB", "LV", "OM", "PA", "PE", "PK", "PR", "QA", "SE", "VE", "VN"]
    
    init(places: [TwitterPlace]) {
        update(places: places)
    }
    
    ///Update countries to update
    mutating func update(places: [TwitterPlace]) {
        places.forEach { (place) in
            if let countryCode = place.countryCode {
                lastUpdates[countryCode] = 0
            }
        }
    }
    
    var nextCountry: String {
        var best: String = "AU"
        var bestValue: TimeInterval = Date().timeIntervalSince1970
        for (key,value) in lastUpdates {
            if GoogleJobData.excludedCodes.contains(key) {
                continue //Don't try and fetch this country
            }
            if value < bestValue {
                best = key
                bestValue = value
            }
        }
        return best
    }
    
}

struct JobStatusData: Codable {
    
    var twitter: TwitterJobData? = nil
    var google: GoogleJobData? = nil
    
}

final class JobStatus: Model, Content {
    
    public static let schema = "job_status"
    
    @ID(key: .id)
    ///Primary key
    public var id: UUID?
    
    @Enum(key: .type)
    public var type: JobStatusType
    
    @Field(key: .jobData)
    public var jobData: JobStatusData
    
    init() {}
    
    init(google: GoogleJobData) {
        type = .googleDaily
        jobData = JobStatusData(google: google)
    }
    
    init(twitter: TwitterJobData) {
        type = .twitter
        jobData = JobStatusData(twitter: twitter)
    }
    
}

struct JobStatusMigration: Migration {
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(JobStatus.schema)
            .id()
            .field(.type, .string) //TODO: Should this be enum?
            .field(.jobData, .json)
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(JobStatus.schema).delete()
    }
    
    public init() {}
    
    
}
