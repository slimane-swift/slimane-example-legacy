//
//  main.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Suv
import Slimane
import SlimaneHTTP

if Process.arguments.count > 1 {
    let mode = Process.arguments[1]
    
    if mode == "--cluster" {
        // For Cluster app
        if Cluster.isMaster {
            let cluster = Cluster(Array(Process.arguments[1..<Process.arguments.count]))
            
            for _ in 0..<OS.cpuCount {
                try! cluster.fork(silent: false)
            }
            
            try! Slimane().listen(port: 3000)
        } else {
            launchApplication()
        }
    }

    else if mode == "--no-slimane" {
        let server = SlimaneHTTP.createServer { result in
            if case .Success(let req, let res) = result {
                res.write("hello")
            }
        }
        
        try! server.bind(Address(host: "0.0.0.0", port: 3000))
        
        try! server.listen()
        
        Loop.defaultLoop.run()
    }
    
} else {
    // for single thread app
    launchApplication()
}
