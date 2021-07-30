//
//  Request.swift
//  NetworkingLayer
//
//  Created by Eric Chen on 2020/7/5.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation

public protocol HTTPRequest {
    associatedtype successResponse: Codable
    associatedtype failureResponse: Codable
    var url: URL { get }
    var method: HTTPMethod { get }
    var parameters: [String : Any] { get }
    var contentType: ContentType { get }
    var authorizationType: AuthorizationType{ get }
    
    var adapters: [RequestAdapter] { get }
    var decisions: [Decision] { get }
}

extension HTTPRequest {
    var adapters: [RequestAdapter] {
        return [method.adapter, RequestContentAdapter(method: method, contentType: contentType, content: parameters), authorizationType.authoriaztionAdapter()]
    }
    var decisions: [Decision] {
        
        return [RefreshTokenDecision(),
                RetryDecision(leftCount: 2),
                BadResponseStatusCodeDecision(),
                DataMappingDecision(condition: { $0.isEmpty }, transform: { _ in "{}".data(using: .utf8)!}),
                ParseResultDecision()
        ]
        
    }
    func buildRequest() throws -> URLRequest {
        let request = URLRequest(url: url)
        return try adapters.reduce(request) { (result, adapter) -> URLRequest in
            try adapter.adapted(result)
        }
    }
}
