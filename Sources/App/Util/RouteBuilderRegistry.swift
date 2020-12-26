//  Created by Alexander Skorulis on 22/11/20.

import Vapor

struct RouteDefinition: Content {
    
    let method: String
    let path: String
    
    let queryParams: [String: String]?
    let url: String?
    
    func withBase(url: String) -> RouteDefinition {
        let fullURL = url + "/" + path
        return RouteDefinition(method: method, path: path, queryParams: queryParams, url: fullURL)
    }
    
}

final class RouteRegistryModel: Content {
    var routes: [String: RouteDefinition] = [:]
    
    init(_ routes: [String: RouteDefinition] = [:]) {
        self.routes = routes
    }
    
    func withBase(url: String) -> RouteRegistryModel {
        let newRoutes = routes.mapValues { $0.withBase(url: url) }
        return RouteRegistryModel(newRoutes)
    }
    
    
}

struct RegistryParams: Decodable {
    let baseURL: String?
}

protocol RegisteredRouteCollection {
    
    func boot(routes: RoutesBuilder, registry: RouteRegistry) throws
    
}

final class RouteRegistry: RouteCollection {
    
    private var model: RouteRegistryModel = RouteRegistryModel()
    private var hasRegistered: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case routes
    }
    
    func register(route: Route, as name: String, queryExample: Decodable?) {
        assert(!hasRegistered, "Registry path should always be added last")
        
        let path = route.path.map { (comp) -> String in
            switch comp {
            case .constant(let text):
                return text
            case .parameter(let param):
                return "{\(param)}"
            case .anything:
                return "*"
            case .catchall:
                return "?"
            }
        }.joined(separator: "/")
        
        let queryParams = extractParams(queryExample)
        model.routes[name] = RouteDefinition(method: route.method.rawValue, path: path, queryParams: queryParams, url: nil)
        
    }
    
    func extractParams(_ example: Decodable?) -> [String: String]? {
        guard let example = example else {
            return nil
        }
        
        var result = [String:String]()
        let mirror = Mirror(reflecting: example)
        for (_, attr) in mirror.children.enumerated() {
            let label = attr.label!.replacingOccurrences(of: "\"", with: "")
            result[label] = "\(type(of:attr.value))"
        }
        
        return result
    }
    
    func boot(routes: RoutesBuilder) throws {
        hasRegistered = true
        
        routes.get { req -> EventLoopFuture<RouteRegistryModel> in
            let params = try req.query.decode(RegistryParams.self)
            var result = self.model
            if let baseURL = params.baseURL ?? req.headers.first(name: .host).map({ "http://" + $0 }) {
                result = result.withBase(url: baseURL)
            }
            return req.eventLoop.makeSucceededFuture(result)
        }
    }
       
}


extension RoutesBuilder {
    
    func register(collection: RegisteredRouteCollection, registry: RouteRegistry) throws {
        try collection.boot(routes: self, registry: registry)
    }
    
}

extension Route {
    
    func register(as name: String, in registry: RouteRegistry, queryExample: Decodable? = nil) {
        registry.register(route: self, as: name, queryExample: queryExample)
    }
    
}
