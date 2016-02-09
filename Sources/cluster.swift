//
//  cluster.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Suv
import SlimaneHTTP
import Slimane

func launchClusterApp() {
    if Cluster.isMaster {
        let cluster = Cluster(Process.arguments)
        
        for _ in 0..<OS.cpuCount {
            try! cluster.fork(silent: false)
        }
        
        try! Slimane().listen(port: 3000)
    } else {
        launchApplication()
    }
}