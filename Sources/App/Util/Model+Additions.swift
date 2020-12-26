//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 18/11/20.
//

import Vapor
import Fluent

extension Model {
    
    func insert(on db: Database) -> EventLoopFuture<Self> {
        return self.create(on: db).map { (_) -> (Self) in
            return self
        }
    }
    
}

extension Array where Element: Model {
    func insertAll(on db: Database) -> EventLoopFuture<[Element]> {
        let createFutures:[EventLoopFuture<Element>] = self.map { $0.insert(on: db)}
        return createFutures.flatten(on: db.eventLoop)
    }
}
