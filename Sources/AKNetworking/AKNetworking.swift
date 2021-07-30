//
//  HTTPClient.swift
//  NetworkingLayer
//
//  Created by Eric Chen on 2020/7/5.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

public class AKNetworking {
    var session: URLSession
    
    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    public func send<Req: HTTPRequest>(_ request:Req, decisions: [Decision]? = nil, completionHandle: @escaping (Result<Req.successResponse, Error>)->Void){
        
        let urlRequest: URLRequest
        
        do {
            try urlRequest = request.buildRequest()
            
        } catch OAuth2Error.passwordGrantUnauthorized(let service, let grant) {
            //retrieve access token
            grant.retrieveAccessToken { (result) in
                switch result{
                case .success(let response):
                    let accessToken = response.accessToken
                    let tokenType = response.tokenType
                    //save access token and token type
                    let keychainByService = KeychainWrapper(serviceName: service)
                    let a = keychainByService.set(tokenType, forKey: "token_type")
                    print(a)
                    keychainByService.set(accessToken, forKey: "access_token")
                    //retry request
                    self.send(request, completionHandle: completionHandle)
                case .failure(let error):
                    completionHandle(.failure(error))
                }
            }
            return
        } catch {
            completionHandle(.failure(error))
            return
        }
        
        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
            
            guard let data = data else{
                completionHandle(.failure(error ?? HTTPError<Req>.nilData))
                return
            }
            
            guard let response = response as? HTTPURLResponse else{
                completionHandle(.failure(HTTPError<Req>.nonHTTPResponse))
                return
            }
            
            self.handleDecisions(request: request, response: response, data: data, decisions: decisions ?? request.decisions, completionHandle: completionHandle)
            
        }
        dataTask.resume()
    }
    
    func handleDecisions<Req: HTTPRequest>(request: Req, response: HTTPURLResponse, data: Data, decisions: [Decision], completionHandle: @escaping (Result<Req.successResponse, Error>)->Void) {
        
        var decisions = decisions
        let currect = decisions.removeFirst()
        
        guard currect.shouldApply(request: request, response: response, data: data) else {
            self.handleDecisions(request: request, response: response, data: data, decisions: decisions, completionHandle: completionHandle)
            return
        }
        
        currect.apply(request: request, response: response, data: data, decisions: decisions) { (action) in
            switch action {
            case .continueWith(let data, let response): //next decision
                self.handleDecisions(request: request, response: response, data: data, decisions: decisions, completionHandle: completionHandle)
            case .restartWith(let decisions): //resent request
                self.send(request, decisions: decisions, completionHandle: completionHandle)
            case .errored(let error): //failure
                completionHandle(.failure(error))
            case .done(let object): //success
                completionHandle(.success(object))
            }
        }
    }
}
