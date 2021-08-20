//
//  Decisions.swift
//  NetworkingLayer2
//
//  Created by 陳仕偉 on 2020/7/13.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

public protocol Decision {
    
    func shouldApply<Req: HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data) -> Bool
    
    func apply<Req: HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], done closure: @escaping (DecisionAction<Req>) -> Void)
    
}

public enum DecisionAction<Req: HTTPRequest>{
    case continueWith(Data, HTTPURLResponse)
    case restartWith([Decision])
    case errored(Error)
    case done(Req.successResponse)
}

//RefreshTokenDecision
struct RefreshTokenDecision: Decision {
    func shouldApply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data) -> Bool {
        return response.statusCode == 401
    }
    
    func apply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], done closure: @escaping (DecisionAction<Req>) -> Void) {
        //get new access token
        switch request.authorizationType {
        case .OAuth2PasswordGrant(let service, _, let refreshTokenRequest):
            let grant = OAuth2PasswordGrant()
            grant.refreshAccessToken(request: refreshTokenRequest) { (result) in
                switch result{
                case .success(let response):
                    let accessToken = response.accessToken
                    KeychainWrapper.standard.set(accessToken, forKey: "\(service)_access_token")
                    closure(.restartWith(decisions))
                case .failure(let error):
                    closure(.errored(error))
                }
            }
        default:
            closure(.errored(NSError(domain: "None oAuth2 auth code grand type", code: 0, userInfo: nil)))
        }
    }
}
//RetryDecision
struct RetryDecision: Decision {
    var leftCount: Int
    
    func shouldApply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data) -> Bool {
        return !(200...299).contains(response.statusCode) && leftCount > 0
    }
    
    func apply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions:[Decision], done closure: @escaping (DecisionAction<Req>) -> Void) {
        var decisions = decisions
        let leftRetryDecision = RetryDecision(leftCount: leftCount - 1 )
        decisions.insert(leftRetryDecision, at: 0)
        closure(.restartWith(decisions))
        
    }
}
//BadResponseStatusCodeDecision
struct BadResponseStatusCodeDecision: Decision {
    func shouldApply<Req>(request: Req, response: HTTPURLResponse, data: Data) -> Bool where Req : HTTPRequest {
        return !(200...299).contains(response.statusCode)
    }
    
    func apply<Req>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], done closure: @escaping (DecisionAction<Req>) -> Void) where Req : HTTPRequest {
        let decoder = JSONDecoder()
        do {
            let apiError = try decoder.decode(Req.failureResponse.self, from: data)
            closure(.errored(HTTPError<Req>.apiError(apiError, response.statusCode)))
        } catch {
            closure(.errored(error))
        }
    }
}
//DataMappingDecision
struct DataMappingDecision: Decision {
    let condition: (Data) -> Bool
    let transform: (Data) -> Data
    
    func shouldApply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data) -> Bool {
        return condition(data)
    }
    
    func apply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], done closure: @escaping (DecisionAction<Req>) -> Void) {
        let newData = transform(data)
        closure(.continueWith(newData, response))
    }
}
//ParseResultDecision
struct ParseResultDecision : Decision {
    func shouldApply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data) -> Bool {
        true
    }
    
    func apply<Req : HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], done closure: @escaping (DecisionAction<Req>) -> Void) {
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(Req.successResponse.self, from: data)
            closure(.done(object))
        } catch {
            closure(.errored(error))
        }
    }
}
