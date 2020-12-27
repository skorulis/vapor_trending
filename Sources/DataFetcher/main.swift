import App
import Vapor

var env = try Environment.detect()
print("Running main with arguments: \(env.arguments)")
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
let config = Configure()
try config.configureFetch(app)
try app.run()
