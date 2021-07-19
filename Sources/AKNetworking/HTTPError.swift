//
//  ResponseError.swift
//  NetworkingLayer
//
//  Created by Eric Chen on 2020/7/5.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation

enum HTTPError<Req: HTTPRequest>: Error {
    case invalidURL
    case nonHTTPResponse
    case nilData
    case tokenError
    case apiError(Req.failureResponse, Int)
    case unauthoriezed(oAuth2ConfigPlist: String)
    case tokenNotExist
}
