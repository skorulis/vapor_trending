//  Created by Alexander Skorulis on 17/11/20

import Vapor

struct RedditTrendingResponse: Codable {
    let subreddit_names: [String]
    let comment_count: Int
    let comment_url: String
}

struct RedditTrendingService {
    
    fileprivate let client: Client
    fileprivate let authService: RedditAuthService
    
    func getTrending() -> EventLoopFuture<RedditTrendingResponse> {
        return client.get("https://reddit.com/api/trending_subreddits.json") { (req) in
            req.headers.add(name: "User-Agent", value: RedditSecrets.userAgent)
        }.flatMapThrowing({ (res) -> RedditTrendingResponse in
            return try res.content.decode(RedditTrendingResponse.self)
        })
    }
    
}

extension Client {
    
    var redditTrendingService: RedditTrendingService {
        return RedditTrendingService(client: self, authService: redditAuthService)
    }
    
}

