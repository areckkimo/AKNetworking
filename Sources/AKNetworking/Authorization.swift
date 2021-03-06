//
//  AuthoriaztionType.swift
//  NetworkingLayer2
//
//  Created by 陳仕偉 on 2020/8/13.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation

public enum AuthorizationType{
    case NoAuth
    case APIKey(key: String, value: String, place: APIKeyPlace)
    case BasicAuth(userName: String, password: String)
    case OAuth2PasswordGrant(service: String, tokenRequest: OAuth2PasswordGrantTokenRequest)
    case JWT
}

public enum APIKeyPlace {
    case Header
    case URLQueryParameter
}


