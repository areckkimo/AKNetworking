//
//  File.swift
//  
//
//  Created by 陳仕偉 on 2021/8/2.
//

import Foundation

public extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else{
            throw NSError()
        }
        return dictionary
    }
}
