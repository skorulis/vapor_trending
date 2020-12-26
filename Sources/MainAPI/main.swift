import App
import Vapor

var env = try Environment.detect()

try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
let config = Configure()
print("Running main with arguments: \(env.arguments)")
if env.arguments.contains("--scheduled") {
    try config.configureFetch(app)
} else {
    try config.configure(app)
}

try app.run()
