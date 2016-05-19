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
import WS
import QWFuture
import Thrush
import Hanger

let env = Process.env["SLIMANE_ENV"] ?? "development"

var port: Int {
    guard let port = Process.env["PORT"] else {
        return 3000
    }
    
    return Int(port)!
}

var host: String {
    if let host = Process.env["BIND"] {
        return host
    }
    return "0.0.0.0"
}

func sessionConfig() -> SessionConfig {
    let storeSetting = Process.env["SESSION_STORE"] ?? "memory"
    let store: SessionStoreType

    if storeSetting.lowercased() == "redis" {
        store = try! RedisStore(loop: Loop.defaultLoop, host: "127.0.0.1", port: 6379)
    } else {
      store = SessionMemoryStore()
    }

    return SessionConfig(
        secret: "my-secret-key",
        expires: 3600, // 1h
        store: store
    )
}

func launchApplication(){
    let app = Slimane()

    app.use { req, res, next in
        next(.Chain(req, res))
    }

    // HTTP body parser
    app.use(BodyParser())

    app.use(SessionMiddleware(conf: sessionConfig()))

    // Static file serving
    app.use(Slimane.Static(root: Process.cwd + "/public"))

    if env == "development" {
        app.use(AccessLogMiddleware())
    }

    // store data into the session
    app.use { req, res, next in
        var req = req
        req.session?["current_time"] = Time()
        next(.Chain(req, res))
    }

    // Index
    app.get("/") { req, responder in
        responder {
            Response(body: "Welcome Slimane!")
        }
    }

    // html render with JSTemplatesViewEngine
    app.get("/render") { req, responder in
        responder {
            let render = Render(engine: MustacheViewEngine(templateData: ["name": "Slimane"]), path: "index")
            return Response(custom: render)
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
    
    // fibonacci with QWFuture
    app.get("/fibo") { req, responder in
        func fibonacci(_ number: Int) -> (Int) {
            if number <= 1 {
                return number
            } else {
                return fibonacci(number - 1) + fibonacci(number - 2)
            }
        }
        
        let future = QWFuture<Int> { (completion: (() throws -> Int) -> ()) in
            completion {
                fibonacci(10)
            }
        }
        
        future.onSuccess { result in
            responder {
                Response(body: "result is \(result)")
            }
        }
    }
    
    // Asynchronous flow controll with Promise
    app.get("/flow_controll") { req, responder in
        let p1 = Promise<Response> { resolve, reject in
            do {
                let request = Request(method: .get, uri: URI(scheme: "http", host: "google.com", path: "/"))
                try _ = Hanger(request: request) {
                    let response = try! $0()
                    resolve(response)
                }
            } catch {
                reject(error)
            }
        }
        
        let p2 = Promise<Response> { resolve, reject in
            do {
                let request = Request(method: .get, uri: URI(scheme: "http", host: "google.com", path: "/"))
                try _ = Hanger(request: request) {
                    let response = try! $0()
                    resolve(response)
                }
            } catch {
                reject(error)
            }
        }

        Thrush.all(promises: [p1, p2]).then { responses in
                responder {
                    Response(body: "\(responses)")
                }
            }.failure { error in
                responder {
                    Response(status: .badRequest, body: "\(error)")
                }
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
    
    // html render with MustacheViewEngine
    app.get("/chat", handler: ChatRoute.index)
    
    app.any { req, res, stream in
        switch req.uri.path! {
        case "/wschat":
            ChatRoute.websocketHandler(req: req, res: res, stream: stream)
        default:
            var res = app.errorHandler(Error.RouteNotFound(path: req.uri.path ?? "/"))
            try! stream.send((res.description+"\r\n").data + res.body.becomeBuffer())
        }
    }

    let text = "Listening slimane http server at \(host):\(port)"
    if Cluster.isMaster {
        print(text)
    } else {
        // Sending message to master process
        Process.send(.Message(text))
    }
    
    app.keepAliveTimeout = 1

    // Bind address, port and listen http server
    try! app.listen(host: host, port: port)
}
