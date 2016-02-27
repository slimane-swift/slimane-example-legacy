//
//  main.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Suv
import Slimane

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
    
} else {
    // for single thread app
    launchApplication()
}
