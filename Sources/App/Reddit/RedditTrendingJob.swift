//  Created by Alexander Skorulis on 17/11/20.

import Vapor
import Queues

struct RedditTrendingJob: ScheduledJob {
    
    typealias Payload = Void
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        print("Getting reddit trends")
        let trends = context.application.client.redditTrendingService.getTrending()
        return trends.flatMap { (response) -> EventLoopFuture<Void> in
            return context.application.db.transaction { (db) -> EventLoopFuture<Void> in
                return TrendItemDAO().findOrCreate(trends: response.subreddit_names, in: db).map { (items) -> (Void) in
                    print("Finished reddit trends")
                    return Void()
                }
            }
        }
        
        
    }
       
}

