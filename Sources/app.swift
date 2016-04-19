//
//  app.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Slimane
import SessionRedisStore
import BodyParser
import Render
import MustacheViewEngine

func launchApplication(){
    let env = Process.env["SLIMANE_ENV"] ?? "development"
    
    let app = Slimane()
    
    // HTTP body parser
    app.use(BodyParser())
    
    // Enable session
    let sessConfig = SessionConfig(
        secret: "my-secret-key",
        expires: 3600 // 1h
    )
    app.use(SessionMiddleware(conf: sessConfig))

    // Static file serving
    app.use(Slimane.Static(root: Process.cwd + "/public"))
    
    if env == "development" {
        app.use(AccessLogMiddleware())
    }
    
    // store data into the session
    app.use { req, res, next in
        var req = req
        req.session?["current_time"] = "\(Time())"
        next(.Chain(req, res))
    }
    
    // Index
    app.get("/") { req, responder in
        responder {
            Response(body: "Welcome Slimane!")
        }
    }
    
    // html render with MustacheViewEngine
    app.get("/render") { req, responder in
        responder {
            let render = Render(engine: MustacheViewEngine(templateData: ["name": "Slimane", "date": "\(Time())"]), path: "index")
            return Response(custome: render)
        }
    }
    
    // routing with parameters
    app.get("/users/:id") { req, responder in
        responder {
            Response(body: "User id is \(req.params["id"]!)")
        }
    }
    
    // form data
    app.post("/form_data") { req, responder in
        guard let formData = req.formData else {
            return responder {
                Response(status: .badRequest)
            }
        }
        
        responder {
            Response(body: "\(formData)")
        }
    }
    
    // json
    app.post("/json") { req, responder in
        guard let json = req.json else {
            return responder {
                Response(status: .badRequest)
            }
        }
        
        responder {
            Response(body: "\(json)")
        }
    }
    
    // for making sure the worker round robin on cluster mode.
    if Cluster.isWorker {
        app.get("/cluster_test") { req, responder in
            responder {
                Response(body: "pid is: \(Process.pid), worker-id is \(Process.env["SUV_WORKER_ID"]!)")
            }
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

    let text = "Listening slimane http server at \(host):\(port)"
    if Cluster.isMaster {
        print(text)
    } else {
        // Sending message to master process
        Process.send(.Message(text))
    }
    
    // Bind address, port and listen http server
    try! app.listen()
}