//  Created by Alexander Skorulis on 7/12/20.

import Foundation

@testable import App
import XCTVapor
import Vapor
import Queues

class TwitterAvailablePlacesJobTests: BaseAppTests {
    
    func testAPIData() {
        let exp = expectation(description: "Get Data")
        _ = app.client.twitterClient.getAvailablePlaces().always({ (result) in
            let places = try? result.get()
            XCTAssertEqual(places?.count, 467)
            let place1 = places?.first
            XCTAssertEqual(place1?.name, "Worldwide")
            XCTAssertEqual(place1?.woeid, 1)
            XCTAssertEqual(place1?.parentid, 0)
            XCTAssertNil(place1?.countryCode)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
    }
    
    func testJob() throws {
        let exp = expectation(description: "Get places")
        _ = TwitterAvailablePlacesJob().run(context: testContext).always { (result) in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
        
        let places = try Place.query(on: app.db).all().wait()
        XCTAssertEqual(places.count, 467)
        
        let googleJob = try JobStatusDAO.get(type: .googleDaily, db: app.db).wait()
        XCTAssertGreaterThan(googleJob?.jobData.google?.lastUpdates.count ?? 0, 0)
        
    }
    
    func testGetPlaces() throws {
        var exp = expectation(description: "Get places empty")
        try app.test(.GET, "/place", afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let places = try res.content.decode([Place].self)
            XCTAssertEqual(places.count, 0)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
        
        exp = expectation(description: "Update places")
        _ = TwitterAvailablePlacesJob().run(context: testContext).always { (result) in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
        
        exp = expectation(description: "Get places full")
        try app.test(.GET, "/place", afterResponse: { (res) in
            XCTAssertEqual(res.status, .ok)
            let places = try res.content.decode([Place].self)
            XCTAssertEqual(places.count, 467)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
        
    }
    
}
