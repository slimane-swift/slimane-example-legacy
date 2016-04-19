//
//  AccessLogMiddleware.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Slimane

// Session
public struct AccessLogMiddleware: MiddlewareType {
    public init(){}

    public func respond(req: Request, res: Response, next: MiddlewareChain) {
        print("[pid:\(Process.pid)]\t\(Time())\t\(req.path ?? "/")")
        next(.Chain(req, res))
    }
}
