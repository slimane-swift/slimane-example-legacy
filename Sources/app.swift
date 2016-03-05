//
//  app.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Core
import Suv
import SlimaneHTTP
import Slimane

func launchApplication(){
    let app = Slimane()
    
    let env = Process.env["SLIMANE_ENV"] ?? "development"
    
    // Body parser
    app.use(BodyParser())
    
    app.use(CookieParser(secret: "secret"))
    
    // Enable Basic authentication
    //app.use(BasicAuthenticationMiddleware())

    // Static File Responder
    app.use(StaticFileServe("\(Process.cwd)/public"))
    
//    // Enable session
//    app.use(SessionHandler(
//        SessionConfig(
//            secret: "secret",
//            expires: Time(tz: .UTC).addDay(7).rfc822
//        )
//    ))
//
//    // handy middleware for session
//    app.use { req, res, next in
//        if let session = req.session {
//            session["current_time"] = Time().string
//        }
//        next(nil)
//    }
    
    if env == "development" {
        app.use { req, res, next in
            print(req.uri.path ?? "/")
            next(nil)
        }
    }
    
    // function style handler
    app.get("/") { req, res in
        res.write("Welcome to Slimane!")
    }

    // RouteType handler
    app.get("/users/:id", UserGetRoute())
    app.post("/users", UserCreateRoute())
    
    // response handler with template rendering
    app.get("/render_sample") { req, res in
        res.render("index", templateData: ["name": "Slimane", "date": Time().string])
    }
    
    if Cluster.isWorker {
        app.get("/worker_info") { req, res in
            res.write("Hi, I'm a pid: \(Process.pid), worker-id: \(Process.env["SUV_WORKER_ID"]!)")
        }
    }

    var port: Int {
        guard let port = Process.env["PORT"] else {
            return 3000
        }
        
        return Int(port)!
    }
    
    var host: String {
        if let host = Process.env["BIND_HOST"] {
            return host
        }
        return "0.0.0.0"
    }
    
    // Bind address, port and listen http server
    print("Listening http server at \(host):\(port)")
    try! app.listen(host: host, port: port)
}

