//
//  chat.swift
//  SlimaneExample
//
//  Created by Yuki Takei on 5/8/16.
//
//

import Slimane
import Render
import JSTemplatesViewEngine
import WS

private var sockets = [WebSocket]()

extension WebSocket {
    func unmanaged() -> Unmanaged<WebSocket> {
        sockets.append(self)
        return Unmanaged.passRetained(self)
    }
    
    func release(_ unmanaged: Unmanaged<WebSocket>){
        if let index = sockets.index(of: self) {
            sockets.remove(at: index)
            unmanaged.release()
        }
        // release strong ref and deinit will be called
        unmanaged.release()
    }
    
    func broadCast(_ data: String){
        for socket in sockets {
            if socket != self {
                socket.send(data)
            }
        }
    }
    
    func broadCast(_ data: Data){
        for socket in sockets {
            if socket != self {
                socket.send(data)
            }
        }
    }
}

struct ChatRoute {
    static func index(to: Request, responder: (Void throws -> Response) -> Void){
        responder {
            let render = Render(engine: JSTemplatesViewEngine(templateData: ["host": host as AnyObject, "port": "\(port)" as AnyObject]), path: "chat.mustache")
            return Response(custom: render)
        }
    }
    
    static func websocketHandler(req: Request, res: Response, stream: AsyncStream){
        _ = WebSocketServer(to: req, with: stream) {
            do {
                let socket = try $0()
                // retain strong ref
                let unmanaged = socket.unmanaged()
                
                socket.onClose { status, _ in
                    print("closed")
                    socket.release(unmanaged)
                }
                
                socket.onText { [unowned socket] in
                    socket.broadCast($0)
                }
                
                socket.onBinary { [unowned socket] in
                    socket.broadCast($0)
                }
                
                socket.onPing { [unowned socket] in
                    socket.pong($0)
                }
            } catch {
                stream.send(Response(status: .badRequest, body: "\(error)").description+"\r\n".data) {_ in }
            }
        }
    }
}