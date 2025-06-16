package hx.well;

import sys.net.Socket;
#if !java
import sys.ssl.Socket as SSLSocket;
#end
import sys.thread.Thread;
import sys.net.Host;
import hx.concurrent.executor.Executor;
import hx.well.http.Request;
import hx.well.route.RouteElement;
import hx.well.http.Response;
import hx.well.route.Route;
import haxe.CallStack;
import haxe.Exception;
import hx.well.service.PublicService;
import hx.well.exception.AbortException;
import hx.well.middleware.AbstractMiddleware;
import hx.well.server.AbstractServer;
import hx.well.http.ResponseStatic;
import hx.well.http.ResponseStatic.abort;
import hx.well.http.RequestStatic;
import hx.well.http.RequestParser;
import hx.well.http.DummyRequest;
import hx.well.facades.Config;
import hx.well.http.ManualResponse;
import haxe.io.Input;

class WebServer {
    public var server:AbstractServer;

    public function new(server:AbstractServer) {
        this.server = server;
    }

    public function startMultiThread():Void {
        Thread.create(this.start);
    }

    public function start():Void {
        var host:Host = server.host();
        var port:Int = server.port();
        var socket:Socket = server.socket();
        var executor:Executor = server.executor();
        var maxConnections:Int = server.maxConnections();

        //socket.setBlocking(false);
        socket.bind(host, port);
        socket.listen(maxConnections); // max connections
        //socket.setFastSend(false);

        while(true) {
            #if !java
            socket.waitForRead();
            #end

            var clientSocket:Socket = socket.accept();
            //clientSocket.setBlocking(false);
            if(clientSocket == null)
                continue;

            // Handle SSLSocket
            #if !java
            if(clientSocket is SSLSocket)
            {
                var sslClientSocket:SSLSocket = cast clientSocket; // This may not be necessary, if !verifyCert
                if(sslClientSocket.verifyCert)
                {
                    try {
                        sslClientSocket.handshake();
                    } catch (e) {
                        try {
                            sslClientSocket.close();

                        } catch (ignored) {
                        }
                        continue;
                    }
                }
            }
            #end

            var threadFunction = () -> {
                handleRequest(clientSocket);
            };
            executor.submit(() -> {
                try {
                    threadFunction();
                } catch (e:Exception) {
                    try {
                        clientSocket.output.close();
                    } catch (ignored) {
                        trace(ignored);
                    }
                    trace(e);
                    //throw e;
                }
            });
        }
    }

    private function handleRequest(socket:Socket):Void {
        var request:Request = null;
        try {
            ResponseStatic.reset();
            RequestStatic.set(null);

            try {
                request = RequestParser.parseFromSocket(socket);
                RequestStatic.set(request);
            } catch (e:AbortException) {
                request = new DummyRequest(socket);
                RequestStatic.set(request);
                throw e;
            }

            processRequest(request);
        } catch(e:AbortException) {
            trace(e);
            handleAbortException(request, e);
        } catch (e:Exception)
        {
            // if any data is not writed
            if(!socket.output.isWrited)
            {
                handleAbortException(request, new AbortException(500));
            }

            var crashDump:String = 'HTTP Server request failed: ${e.message}\n${CallStack.toString(e.stack)}';
            trace(crashDump);
        } catch (e:Dynamic) {
            trace(e);
            sys.io.File.saveContent('webServer.dump', e);
        }
    }

    private function handleAbortException(request:Request, exception:AbortException):Void
    {
        try {
            var socket:Socket = request.socket;
            var response:Response;
            var routeElement:RouteElement = Route.resolveStatusCode(exception.statusCode + "");
            if(routeElement != null)
            {
                response = routeElement.getHandler().execute(request);
            }else{
                // Create blank response
                response = new Response();
            }

            if(response.statusCode == null)
                response.statusCode = exception.statusCode;

            writeResponse(request.socket, response);
        } catch (e) {
            trace(e);
            request.socket.close();
            //trace(e);
        }
    }

    private function processRequest(request:Request):Void
    {
        var routeData:{route:RouteElement, params:Map<String, String>} = Route.resolveRequest(request);
        if(routeData == null)
        {
            var publicRouterElement = new RouteElement();
            publicRouterElement.handler(Route.publicService);
            routeData = {route: publicRouterElement, params: new Map()};
        }
        var routerElement = routeData.route;
        request.routeParameters = routeData.params ?? new Map();

        var middlewares:Array<AbstractMiddleware> = [];
        var middlewareClasses:Array<Class<AbstractMiddleware>> = server.middlewares().concat(@:privateAccess routerElement.middlewares);

        var middlewareIndex = 0;
        var executeMiddleware:Request->Null<Response> = null;
        
        executeMiddleware = function(req:Request):Null<Response> {
            if(middlewareIndex >= middlewareClasses.length) {
                return executeHandler(req, routerElement);
            }

            var currentMiddlewareClass = middlewareClasses[middlewareIndex];
            var currentMiddleware = Type.createInstance(currentMiddlewareClass, []);
            middlewares.push(currentMiddleware);
            middlewareIndex++;
            
            try {
                return currentMiddleware.handle(req, executeMiddleware);
            } catch (e) {
                disposeMiddlewares(middlewares);
                throw e;
            }
        };

        try {
            var response = executeMiddleware(request);
            if(response != null) {
                disposeMiddlewares(middlewares);
                writeResponse(request.socket, response);
            }
        } catch (e) {
            disposeMiddlewares(middlewares);
            throw e;
        }
    }

    private function executeHandler(request:Request, routerElement:RouteElement):Null<Response> {
        var handler = routerElement.getHandler();
        var socket = request.socket;

        if(!routerElement.getStream())
        {
            request.parseBody(socket.input);

            if(!handler.validate())
            {
                abort(404);
            }
        }

        #if debug
        trace('${request.method} ${request.path}, stream: ${routerElement.getStream()}');
        #end
        return handler.execute(request);
    }

    private function disposeMiddlewares(middlewares:Array<AbstractMiddleware>):Void
    {
        while (middlewares.length > 0)
        {
            try {
                middlewares.shift().dispose();
            } catch (e:Exception) {
                // TODO: log
                trace(e);
            }
        }
    }

    public static function writeResponse(socket:Socket, response:Response)
    {
        if(response is ManualResponse)
            return;

        if(response != null)
        {
            socket.output.writeString(response.generateHeader());

            var responseInput:Input = response.toInput();
            socket.output.writeInput(responseInput);

            try {
                responseInput.close();
            } catch (e) {
                // TODO: Log error
                trace(e);
            }

            socket.output.flush();
        }
        socket.output.close();

        if(response != null && response.after != null)
            response.after();
    }

    public function stop():Void {

    }
}