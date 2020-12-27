import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Queues
import QueuesRedisDriver

public struct Configure {
    
    public init() {}
    
    // configure the application for database access
    public func configure(_ app: Application) throws {
        configureDatabase(app)
        
        configureMigrations(app)
        do {
            print("Running auto migration")
            try app.autoMigrate().wait()
        } catch {
            print("Migration failure \(error)")
        }
        
        app.http.server.configuration.port = 7000
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        ContentConfiguration.global.use(encoder: encoder, for: .json)
        
        // register routes
        try routes(app)
    }
    
    // configure the application for database updating
    public func configureFetch(_ app: Application) throws {
        configureDatabase(app)
        
        configureMigrations(app)
        print("Running auto migration")
        try app.autoMigrate().wait()
        
        try configureJobs(app)
    }
    
    private func configureJobs(_ app: Application) throws {
        //Setup queues
        let host = Environment.get("REDIS_HOST") ?? "127.0.0.1"
        let port = "6379"

        try app.queues.use(.redis(url: "redis://\(host):\(port)"))
        
        let queueConfig = QueuesConfiguration(refreshInterval: .seconds(1), persistenceKey: "test", workerCount: 1, logger: app.logger)
        let testContext = QueueContext(queueName: .default, configuration: queueConfig, application: app, logger: app.logger, on: app.eventLoopGroup.next())
        
        
        _ = RedditTrendingJob().run(context: testContext)
        _ = TwitterAvailablePlacesJob().run(context: testContext)
        _ = GoogleTrendingJob().run(context: testContext)
        
        app.queues.schedule(TwitterGetTrendsJob()).minutely().at(1)
        app.queues.schedule(TwitterGetTrendsJob()).minutely().at(15)
        app.queues.schedule(TwitterGetTrendsJob()).minutely().at(30)
        app.queues.schedule(TwitterGetTrendsJob()).minutely().at(59)
        
        app.queues.schedule(GoogleTrendingJob()).minutely().at(10)
    }
    
    private func configureDatabase(_ app: Application) {
        if app.environment.name == "testing" {
            app.databases.use(.sqlite(.memory), as: .sqlite)
            //app.databases.database(.sqlite, logger: Logger(label: "DB"), on: app.eventLoopGroup.next(), history: nil)
            return
        }
        
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "postgres",
            password: Environment.get("DATABASE_PASSWORD") ?? "1234",
            database: Environment.get("DATABASE_NAME") ?? "trending"
        ), as: .psql)
    }
    
    private func configureMigrations(_ app: Application) {
        app.migrations.add(TrendItemMigration())
        app.migrations.add(RedditTrendMigration())
        app.migrations.add(CountryMigration())
        app.migrations.add(PlaceMigration())
        app.migrations.add(TwitterDataPointMigration())
        app.migrations.add(GoogleDataPointMigration())
        app.migrations.add(JobStatusMigration())
        
    }

    
}





