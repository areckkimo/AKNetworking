//
//  File.swift
//  
//
//  Created by 陳仕偉 on 2021/7/20.
//

import Foundation

public class OAuth2PasswordGrant{
    var request: OAuth2PasswordGrantAccessTokenRequest
    
    init(request: OAuth2PasswordGrantAccessTokenRequest) {
        self.request = request
    }
    
    typealias Success = OAuth2PasswordGrantAccessTokenRequest.successResponse
    
    func retrieveAccessToken(completion: @escaping (Result<Success, Error>)->Void) {
        let akNetworking = AKNetworking()
        akNetworking.send(request) { (result) in
            switch result{
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct OAuth2PasswordGrantAccessTokenRequest: HTTPRequest {
    var url: URL
    
    var parameters: [String : Any] {
        return defaultParameters.encode()
    }
    
    var authorizationType: AuthorizationType = .NoAuth
    
    typealias successResponse = OAuth2PasswordGrantSuccessType
    typealias failureResponse = OAuth2PasswordGrantFailType
    
    var method: HTTPMethod = .POST
    var contentType: ContentType = .xWWWFormURLEncoded
    
    var defaultParameters: OAuth2PasswordGrantRequestParameters
}

protocol OAuth2PasswordGrantDecodable {
    
    associatedtype sucessDecodeType: Codable
    associatedtype failureDecodeType: Codable
    
    var accessTokenEndPoint: URL {get}
    var request: OAuth2PasswordGrantRequestParameters{get}
}

protocol OAuth2PasswordGrantRequestParameters {
    var grantType: String {get}
    var username: String {get}
    var password: String {get}
    
    func encode() -> [String: Any]
}

extension OAuth2PasswordGrantRequestParameters {
    var grantType: String {
        return "password"
    }
}

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

struct OAuth2PasswordGrantSuccessType: Codable {
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

struct OAuth2PasswordGrantFailType: Codable {
    var error: String?
    var errorDescription: String?
    var errorURI: String?
}

enum OAuth2Error: Error {
    case passwordGrantUnauthorized(service: String, grant: OAuth2PasswordGrant)
}
