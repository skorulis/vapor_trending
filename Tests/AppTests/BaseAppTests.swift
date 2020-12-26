//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 7/12/20.
//

@testable import App
import XCTVapor
import Queues

class BaseAppTests: XCTestCase {
    
    var app: Application!
    
    var testContext: QueueContext {
        let queueConfig = QueuesConfiguration(refreshInterval: .seconds(1), persistenceKey: "test", workerCount: 1, logger: app.logger)
        return QueueContext(queueName: .default, configuration: queueConfig, application: app, logger: app.logger, on: app.eventLoopGroup.next())
    }
    
    override func setUp() {
        super.setUp()
        app = Application(.testing)    
        
        app.clients.use { (app) -> (Client) in
            return MockClient(rootPath: "./Tests/Data", eventLoop: app.eventLoopGroup.next(), fileio: app.fileio)
        }
        let config = Configure()
        try! config.configure(app)
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }
    
}
