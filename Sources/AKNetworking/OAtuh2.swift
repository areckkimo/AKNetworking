//
//  File.swift
//  
//
//  Created by 陳仕偉 on 2021/7/20.
//

import Foundation

class OAuth2PasswordGrant<S, F>{
    var accessTokenURL: URL
    var parameters: OAuth2PasswordGrantRequestParameters
    
    init(accessTokenURL: URL, parameters: OAuth2PasswordGrantRequestParameters) {
        self.accessTokenURL = accessTokenURL
        self.parameters = parameters
    }
    
    func retrieveAccessToken<Success: Codable, Fail: Codable>(responseSuccess: Success, responseFail: Fail, completion: @escaping (Result<Success, Error>)->Void) {
        let akNetworking = AKNetworking()
        let request = OAuth2PasswordGrantAccessTokenRequest<Success, Fail>(url: accessTokenURL, defaultParameters: parameters)
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

struct OAuth2PasswordGrantAccessTokenRequest<Success: Codable, Failure: Codable>: HTTPRequest {
    var url: URL
    
    var parameters: [String : Any] {
        return defaultParameters.encode()
    }
    
    var authorizationType: AuthorizationType = .NoAuth
    
    typealias successResponse = Success
    typealias failureResponse = Failure
    
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

protocol OAuth2PasswordGrantSuccessResponse: Codable {
    var accessToken: String {get}
    var tokenType: String {get}
    var expiresIn: Int? {get}
    var refreshToken: String? {get}
}

protocol OAuth2PasswordGrantFailureResponse: Codable {
    var error: String? {get}
    var errorDescription: String? {get}
    var errorURI: String? {get}
}

enum OAuth2Error: Error {
    case passwordGrantUnauthorized(service: String)
}
