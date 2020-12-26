//  Created by Alexander Skorulis on 18/11/20.

import Vapor
import Secrets

struct TwitterPlace: Codable {
    let name: String
    let url: String
    let parentid: Int
    let country: String
    let woeid: Int32
    let countryCode: String?
}

struct TwitterTrend: Codable {
    let name: String
    let tweet_volume: Int?
}

struct TwitterTrendResponse: Codable {
    
    let trends: [TwitterTrend]
    
}

struct TwitterClient {
    
    let client: Client
    
    func getAvailablePlaces() -> EventLoopFuture<[TwitterPlace]> {
        return client.get("https://api.twitter.com/1.1/trends/available.json") { (req) in
            req.headers.bearerAuthorization = BearerAuthorization(token: TwitterSecrets.bearerToken)
            req.mock(path: "Twitter/places.json", client)
        }.flatMapThrowing { (res) -> [TwitterPlace] in
            return try res.content.decode([TwitterPlace].self)
        }
    }
    
    func getTrends(woeid: Int32) -> EventLoopFuture<[TwitterTrend]> {
        return client.get("https://api.twitter.com/1.1/trends/place.json?id=\(woeid)") { (req) in
            req.headers.bearerAuthorization = BearerAuthorization(token: TwitterSecrets.bearerToken)
            req.mock(path: "Twitter/trends.json", client)
        }.flatMapThrowing { (res) -> [TwitterTrendResponse] in
            return try res.content.decode([TwitterTrendResponse].self)
        }.map { (result) -> ([TwitterTrend]) in
            return result.first?.trends ?? []
        }
    }
    
}

extension Client {
    
    var twitterClient: TwitterClient {
        return TwitterClient(client: self)
    }
    
}
