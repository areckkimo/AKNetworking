//
//  RequestAdapter.swift
//  NetworkingLayer2
//
//  Created by 陳仕偉 on 2020/7/9.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

protocol RequestAdapter {
    func adapted(_ request: URLRequest) throws -> URLRequest
}

struct AnyAdapter: RequestAdapter {
    var block: (URLRequest) throws -> URLRequest
    func adapted(_ request: URLRequest) throws -> URLRequest {
        return try block(request)
    }
}

struct RequestContentAdapter: RequestAdapter {
    var method: HTTPMethod
    var contentType: ContentType
    var content: [String: Any]
    func adapted(_ request: URLRequest) throws -> URLRequest {
        if method == .GET {
            return try URLQueryDataAdapter(data: content).adapted(request)
        }else{
            let headerAdapter = contentType.headerAdapter
            let dataAdapter = contentType.dataAdapter(for: content)
            return try dataAdapter.adapted(try headerAdapter.adapted(request))
        }
    }
}

//MARK: - Data Encoded
struct URLQueryDataAdapter: RequestAdapter {
    var data: [String: Any]
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        
        guard let url = request.url else{
            return request
        }
        guard var urlComponents = URLComponents(string: url.absoluteString) else {
            return request
        }
        urlComponents.queryItems = data.map{
            URLQueryItem(name: $0.key, value: $0.value as? String)
        }
        request.url = urlComponents.url
        return request
    }
}

struct XWWWURLEncodedDataAdapter: RequestAdapter {
    var data: [String: Any]
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.httpBody = data.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        return request
    }
}

struct JSONDataAdapter: RequestAdapter {
    var data: [String: Any]
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.httpBody = try? JSONSerialization.data(withJSONObject: data, options: [])
        return request
    }
}

//MARK: - API Auth

struct BasicAuthAdapter: RequestAdapter {
    let userName: String
    let password: String
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        let authValue = "\(userName):\(password)".data(using: .utf8)?.base64EncodedString()
        request.addValue("Basic \(authValue!)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct APIKeyAuthAdapter: RequestAdapter {
    let key: String
    let value: String
    let place: APIKeyPlace
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        switch place {
        case .Header:
            request.addValue(value, forHTTPHeaderField: key)
        case .URLQueryParameter:
            guard let url = request.url else{
                return request
            }
            guard var urlComponents = URLComponents(string: url.absoluteString) else {
                return request
            }
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
            request.url = urlComponents.url
        }
        return request
    }
}

struct OAuth2PasswordGrantAdapter: RequestAdapter {
    let service: String
    let grant: OAuth2PasswordGrant
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        let keychainByService = KeychainWrapper(serviceName: service)
        guard let accessToken = keychainByService.string(forKey: "access_token"), let tokenType = keychainByService.string(forKey: "token_type") else {
            throw OAuth2Error.passwordGrantUnauthorized(service: service, grant: grant)
        }
        request.addValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

extension HTTPMethod {
    var adapter: AnyAdapter {
        return AnyAdapter { request in
            var request = request
            request.httpMethod = self.rawValue
            return request
        }
    }
}

extension ContentType {
    var headerAdapter: AnyAdapter {
        return AnyAdapter { request in
            var request = request
            request.setValue(self.rawValue, forHTTPHeaderField: "Content-Type")
            return request
        }
    }
    func dataAdapter(for data: [String: Any]) -> RequestAdapter {
        switch self {
        case .JSON:
            return JSONDataAdapter(data: data)
        case .xWWWFormURLEncoded:
            return XWWWURLEncodedDataAdapter(data: data)
        default :
            return AnyAdapter { $0 }
        }
    }
}

extension AuthorizationType {
    func authoriaztionAdapter()->RequestAdapter{
        switch self {
        case .APIKey(let key, let value, let place):
            return APIKeyAuthAdapter(key: key, value: value, place: place)
        case .BasicAuth(let userName, let password):
            return BasicAuthAdapter(userName: userName, password: password)
        case .OAuth2PasswordGrant(let service, let grant):
            return OAuth2PasswordGrantAdapter(service: service, grant: grant)
        default:
            return AnyAdapter { $0 }
        }
    }
}
