//  Created by Alexander Skorulis on 24/12/20.

@testable import App
import XCTVapor
import Vapor
import Queues

class GoogleTrendingJobTests: BaseAppTests {
    
    func testClient() {
        let exp = expectation(description: "Get google data")
        _ = app.client.googleClient.getDailyTrends(countryCode: "AU").always({ (result) in
            let trends = try? result.get()
            XCTAssertEqual(trends?.trendingSearchesDays.count, 1)
            let day = trends?.trendingSearchesDays[0]
            XCTAssertEqual(day?.trendingSearches.count, 20)
            let search = day?.trendingSearches[0]
            XCTAssertEqual(search?.title.query, "NBA")
            XCTAssertEqual(search?.formattedTraffic, "100K+")
            
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 10)
    }
    
    func testJob() throws {
        var exp = expectation(description: "Get places")
        _ = TwitterAvailablePlacesJob().run(context: testContext).always { (result) in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        
        exp = expectation(description: "Get google trends")
        _ = GoogleTrendingJob().run(context: testContext).always({ (result) in
            exp.fulfill()
            
        })
        
        wait(for: [exp], timeout: 10)
        
        let dataPoints = try GoogleDataPoint.query(on: app.db).all().wait()
        XCTAssertEqual(dataPoints.count, 20)
    }
    
}
