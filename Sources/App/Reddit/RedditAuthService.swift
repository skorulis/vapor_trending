//  Created by Alexander Skorulis on 17/11/20.

import Vapor

private struct RedditAuthBody: Encodable {
    let username = RedditSecrets.username
    let password = RedditSecrets.password
    let grant_type = "password"
}

struct RedditAuthResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
}

struct RedditAuthService {
    
    fileprivate let client: Client
    
    func authorize() -> EventLoopFuture<RedditAuthResponse> {
        let basic = BasicAuthorization(username: RedditSecrets.clientId, password: RedditSecrets.secret)
        
        let result = client.post(URI(string: RedditSecrets.authURLString)) { req in
            req.headers.basicAuthorization = basic
            try req.content.encode(RedditAuthBody(), as: HTTPMediaType.urlEncodedForm)
        }
        
        return result.flatMapThrowing { (res) -> RedditAuthResponse in
            return try res.content.decode(RedditAuthResponse.self)
        }
    }
    
}


extension Client {
    
    var redditAuthService: RedditAuthService {
        return RedditAuthService(client: self)
    }
}
