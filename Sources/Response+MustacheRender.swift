//
//  Response+MustacheRender.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import HTTP
import SlimaneHTTP
import Slimane
import Suv
import Mustache

public typealias TemplateData = MustacheBoxable

extension HTTPResponse {
    
    public func renderError(status: Status = .BadRequest, error: ErrorType){
        self.status(status)
        Logger.fatal(error)
        self.write("\(error)")
    }
    
    public func render(path: String, viewPath: String = "views", fileExtension: String = "mustache", templateData: TemplateData) {
        self.setHeader("Content-Type", "text/html")
        
        let absViewPath = "\(Process.cwd)/\(viewPath)"
        
        print("\(absViewPath)/\(path).\(fileExtension)")
        
        FS.readFile("\(absViewPath)/\(path).\(fileExtension)") {[unowned self] result in
            if case .Error(let err) = result {
                return self.renderError(error: err)
            }
            
            if case .Success(let buf) = result {
                do {
                    let template = try Template(string: buf.toString()!)
                    let htmlString = try template.render(Box(boxable: templateData))
                    self.write(htmlString)
                    
                } catch {
                    return self.renderError(error: error)
                }
            }
            
        }
    }
    
}
