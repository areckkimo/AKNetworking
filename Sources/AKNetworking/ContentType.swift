//
//  ContentType.swift
//  NetworkingLayer
//
//  Created by Eric Chen on 2020/7/5.
//  Copyright © 2020 Eric Chen. All rights reserved.
//

import Foundation

enum ContentType: String {
    case none
    case formData = "multipart/form-data"
    case xWWWFormURLEncoded = "application/x-www-form-urlencoded"
    case JSON = "application/json"
    case XML = "application/xml"
}
