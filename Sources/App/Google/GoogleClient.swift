//  Created by Alexander Skorulis on 22/12/20.

import Vapor

struct GoogleClient {
    
    let client: Client
    
    private var baseURL: String {
        return Environment.get("GOOGLE_API") ?? "http://localhost:5001/"
    }
    
    func getDailyTrends(countryCode: String) -> EventLoopFuture<GoogleDailyTrendsResponse> {
        let url = URI(string: baseURL + "daily/\(countryCode)")
        return client.get(url) { (req) in
            req.mock(path: "Google/daily_trends.json", client)
        }
        .flatMapThrowing { (res) -> GoogleDailyTrendsResponse in
            return try res.content.decode(GoogleDailyTrendsResponse.self)
        }
    }
    
}



extension Client {
    
    var googleClient: GoogleClient {
        return GoogleClient(client: self)
    }
    
}
