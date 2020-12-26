import Fluent
import Vapor

func routes(_ app: Application) throws {
    let registry = RouteRegistry()
    try app.register(collection: TrendController(), registry: registry)
    try app.register(collection: PlaceController(), registry: registry)
    try app.register(collection: StatsController(), registry: registry)
    
    try app.register(collection: registry)
    
}
