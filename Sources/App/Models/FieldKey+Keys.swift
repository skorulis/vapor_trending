//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import Fluent

extension FieldKey {
    static var countryCode: Self { "country_code" }
    static var type: Self { "type" }
    static var jobData: Self { "job_data" }
    static var name: Self { "name" }
    static var countryId: Self { "country_id" }
    static var key: Self { "key" }
    static var display: Self { "display" }
    static var createdAt: Self { "created_at" }
    static var updatedAt: Self { "updated_at" }
    static var placeId: Self { "place_id" }
    static var trendId: Self { "trend_id" }
    static var value: Self { "value" }
}
