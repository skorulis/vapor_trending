//  Created by Alexander Skorulis on 23/12/20.

import Vapor
import XCTVapor

extension XCTHTTPResponse {
    
    var bodyString: String {
        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
        return String(data: data, encoding: .utf8) ?? "Error parsing body"
    }
    
}
