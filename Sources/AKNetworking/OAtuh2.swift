//
//  File.swift
//  
//
//  Created by 陳仕偉 on 2021/7/20.
//

import Foundation
import SwiftKeychainWrapper

public class OAuth2PasswordGrant{
    
    func retrieveAccessToken(request: OAuth2PasswordGrantTokenRequest, completion: @escaping (Result<OAuth2PasswordGrantTokenRequest.successResponse, Error>)->Void) {
        let networking = AKNetworking()
        networking.send(request) { (result) in
            switch result{
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func refreshAccessToken(request: OAuth2PasswordGrantRefreshTokenRequest, completion: @escaping (Result<OAuth2PasswordGrantRefreshTokenRequest.successResponse, Error>)->Void){
        let networking = AKNetworking()
        networking.send(request) { (result) in
            switch result{
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - password grand retrieve access token
public struct OAuth2PasswordGrantTokenRequest: HTTPRequest {
    public var url: URL
    
    public var parameters: [String : Any] {
        return customParameters.encode()
    }
    
    public typealias successResponse = OAuth2PasswordGrantSuccessResponse
    public typealias failureResponse = OAuth2PasswordGrantFailResponse
    
    public var method: HTTPMethod = .POST
    public var contentType: ContentType = .xWWWFormURLEncoded
    
    var customParameters: OAuth2PasswordGrantTokenRequestParameters
    
    public init(url: URL, parameters: OAuth2PasswordGrantTokenRequestParameters) {
        self.url = url
        self.customParameters = parameters
    }
}

public protocol OAuth2PasswordGrantTokenRequestParameters {
    var grantType: String {get}
    var username: String {get}
    var password: String {get}
    
    func encode() -> [String: Any]
}

public extension OAuth2PasswordGrantTokenRequestParameters {
    var grantType: String {
        return "password"
    }
}

public struct OAuth2PasswordGrantSuccessResponse: Codable {
    var accessToken: String
    var tokenType: String
    var expiresIn: Int?
    var refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

public struct OAuth2PasswordGrantFailResponse: Codable {
    var error: String?
    var errorDescription: String?
    var errorURI: String?
}

// MARK: - password grand refresh access token
public struct OAuth2PasswordGrantRefreshTokenRequest: HTTPRequest {
    
    public typealias successResponse = OAuth2PasswordGrantSuccessResponse
    public typealias failureResponse = OAuth2PasswordGrantFailResponse
    
    public var url: URL
    public var parameters: [String : Any] {
        return customParameters.encode()
    }
    var customParameters: OAuth2PasswordGrantRefreshTokenRequestParameters
    public var method: HTTPMethod = .POST
    public var contentType: ContentType = .xWWWFormURLEncoded
    public init(url: URL, parameters: OAuth2PasswordGrantRefreshTokenRequestParameters) {
        self.url = url
        self.customParameters = parameters
    }
}

public protocol OAuth2PasswordGrantRefreshTokenRequestParameters {
    var grantType: String {get}
    var service: String {get}
    func encode() -> [String: Any]
}
public extension OAuth2PasswordGrantRefreshTokenRequestParameters {
    var grantType: String {
        return "refresh_token"
    }
    var refreshToken: String {
        KeychainWrapper.standard.string(forKey: "\(service)_refresh_token") ?? ""
    }
    func encode() -> [String: Any] {
        return ["grant_type": grantType, "refresh_token": refreshToken]
    }
}

public enum OAuth2Error: Error {
    case passwordGrantUnauthorized(service: String, tokenRequest: OAuth2PasswordGrantTokenRequest, refreshTokenRequest: OAuth2PasswordGrantRefreshTokenRequest)
}

/*
public protocol OAuth2PasswordGrantSuccessResponse: Codable {
    var accessToken: String {get}
    var tokenType: String {get}
    var expiresIn: Int? {get}
    var refreshToken: String? {get}
}

public protocol OAuth2PasswordGrantFailureResponse: Codable {
    var error: String? {get}
    var errorDescription: String? {get}
    var errorURI: String? {get}
}
 
public protocol OAuth2PasswordGrantDecodable {
 associatedtype sucessDecodeType: Codable
 associatedtype failureDecodeType: Codable
 
 var accessTokenEndPoint: URL {get}
 var request: OAuth2PasswordGrantTokenRequestParameters{get}
}
 */
