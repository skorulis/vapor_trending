//  Created by Alexander Skorulis on 31/12/20.

import FluentSQL


extension SQLRow {
    
    ///Decode an int despite the data type coming back from SQL
    func decodeInt(column: String) throws -> Int {
        if let intValue = try? self.decode(column: column, as: Int.self) {
            return intValue
        }
        let doubleValue = try self.decode(column: column, as: Double.self)
        return Int(doubleValue)
    }
    
}
