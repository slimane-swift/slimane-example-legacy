//
//  BasicAuthenticationMiddleware.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import SlimaneHTTP
import Slimane

// Session
struct BasicAuthenticationMiddleware: MiddlewareType {
    
    init(){}
    
    private func response401(res: Response){
        res.setHeader("Content-Type", "text/html")
        res.setHeader("WWW-Authenticate", "Basic realm=\"Restricted\"")
        res.status(.Unauthorized)
        res.write("Authorization Required")
    }
    
    func handleRequest(req: Request, res: Response, next: MiddlewareChain) throws {
        guard let auth = req.headers["Authorization"] where auth.splitBy(" ").count > 1 else {
            return response401(res)
        }
        
        // user: jack
        // password: password
        if auth.splitBy(" ")[1] == "amFjazpwYXNzd29yZA==" {
            return next(nil)
        }
        
        response401(res)
    }
}