//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 7/12/20.
//

import Foundation
import Vapor

struct ContentPrinter {
    
    static func dump(res: ClientResponse) {
        dump(body: res.body)
    }
    
    static func dump(body: ByteBuffer?) {
        guard let body = body else {
            return
        }
        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
        if let text = String(data: data, encoding: .utf8) {
            print(text)
        }
    }
    
}
