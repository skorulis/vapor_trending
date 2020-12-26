//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import Fluent

struct JobStatusDAO {
    
    static func get(type: JobStatusType, db: Database) -> EventLoopFuture<JobStatus?> {
        return JobStatus.query(on: db).filter(\.$type == type).first()
    }
    
}
