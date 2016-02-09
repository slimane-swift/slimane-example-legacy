//
//  users.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import SlimaneHTTP
import Slimane

struct UserGetRoute: RouteType {
    func handleRequest(req: Request, res: Response) throws {
        res.write("Hi! My userID is \(req.params["id"]!)")
    }
}

struct UserCreateRoute: RouteType {
    func handleRequest(req: Request, res: Response) throws {
        guard let json = req.jsonBody, let _name = json["name"], userName = _name.stringValue else {
            return res.status(.BadRequest).write("name is required")
        }
        
        res.write("The user \(userName) was created")
    }
}