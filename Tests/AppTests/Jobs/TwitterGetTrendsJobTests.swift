//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 9/12/20.
//

@testable import App
import XCTVapor
import Vapor
import Queues

class TwitterGetTrendsJobTests: BaseAppTests {
    
    func testTrends() throws {
        //Load places
        var exp = expectation(description: "Get places")
        _ = TwitterAvailablePlacesJob().run(context: testContext).always { (result) in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        
        //Load trends
        exp = expectation(description: "Get trends")
        _ = TwitterGetTrendsJob().run(context: testContext).always { (result) in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        
        //Check trends exist
        exp = expectation(description: "Get trends")
        try app.test(.GET, "/trend/top", afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let trends = try res.content.decode(TopTrendsResponse.self)
            XCTAssertEqual(trends.twitter.count, 41)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
        
        //Check trends exist
        exp = expectation(description: "Get trends with id")
        try app.test(.GET, "/trend/top?placeId=2", afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let trends = try res.content.decode(TopTrendsResponse.self)
            XCTAssertEqual(trends.twitter.count, 0)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
        
    }
    
}
