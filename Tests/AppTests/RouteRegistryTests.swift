//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 7/12/20.
//

@testable import App
import XCTVapor

class RouteRegistry: BaseAppTests {
    
    func testGetRoutes() throws {
        try app.test(.GET, "/", afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let routes = try res.content.decode(RouteRegistryModel.self)
            XCTAssertGreaterThan(routes.routes.count, 4)
        })
    }
    
}
