//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 7/12/20.
//

import Foundation
import Vapor


extension ClientRequest {
    
    mutating func meta(header: String, value: String, _ client: Client) {
        //Meta data is only added for mock clients
        if client is MockClient {
            headers.add(name: header, value: value)
        }
    }
    
    mutating func mock(path: String, _ client: Client) {
        meta(header: "mockPath", value: path, client)
    }
    
}

struct MockClient: Client {
    
    let rootPath: String
    var eventLoop: EventLoop
    let fileio: NonBlockingFileIO
    
    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        guard let mockPath: String = request.headers["mockPath"].first else {
            return eventLoop.makeSucceededFuture(ClientResponse(status: .badRequest, headers: HTTPHeaders(), body: nil))
        }
        let url = URL(fileURLWithPath: "\(rootPath)/\(mockPath)")
        let data = try! Data(contentsOf: url)
        
        let bba = ByteBufferAllocator()
        let buffer = bba.buffer(data: data)
        var headers = HTTPHeaders()
        headers.contentType = .json
        let response = ClientResponse(status: .ok, headers: headers, body: buffer)
        return eventLoop.makeSucceededFuture(response)
        
        /*return fileio.openFile(path: "\(rootPath)/\(mockPath)", eventLoop: eventLoop).flatMap { (handle, region) -> EventLoopFuture<ClientResponse> in
            defer { try! handle.close() }
            return fileio.read(fileRegion: region, allocator: ByteBufferAllocator(), eventLoop: eventLoop).map { (buffer) -> (ClientResponse) in
                return ClientResponse(status: .ok, headers: HTTPHeaders(), body: buffer)
            }
        }*/
        
    }
    
    
    
    func delegating(to eventLoop: EventLoop) -> Client {
        return self
    }
    
    
}
