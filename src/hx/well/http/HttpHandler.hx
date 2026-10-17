package hx.well.http;

import hx.well.http.Request;
import hx.well.route.RouteElement;
import hx.well.http.Response;
import hx.well.route.Route;
import haxe.Exception;
import hx.well.exception.AbortException;
import hx.well.middleware.AbstractMiddleware;
import hx.well.http.ResponseStatic.abort;
import hx.well.template.Status500Template;
import hx.well.template.StatusTemplate;
import hx.well.type.AttributeType;
import haxe.CallStack;
import hx.well.http.driver.IDriverContext;
import hx.well.route.RoutePattern;
import hx.well.http.driver.socket.SocketInput;
import hx.well.websocket.AbstractWebSocketHandler;

@:access(hx.well.exception.AbortException)
class HttpHandler {
    public static function handleAbortException(request:Request, exception:AbortException):Void
    {
        try {
            if(exception.statusCode == 500) {
                var actualException:Exception = exception.parent != null ? exception.parent : exception;
                trace(actualException, CallStack.toString(actualException.stack));
                request.setAttribute(AttributeType.Exception, actualException);
            }

            var response:Response;
            var routeElement:RouteElement = Route.resolveStatusCode(exception.statusCode + "");
            if(routeElement != null)
            {
                response = routeElement.getHandler().execute(request);
            } else if(exception.statusCode == 500) {
                response = new Status500Template(exception.statusCode).execute(request);
            } else {
                response = new StatusTemplate(exception.statusCode).execute(request);
            }

            if(response.statusCode == null)
                response.statusCode = exception.statusCode;

            request.context.writeResponse(response);
        } catch (e:Exception) {
            trace(e, CallStack.toString(e.stack));
            // TODO: Log the exception
        }
    }

    public static function process(context:IDriverContext):Void
    {
        RequestStatic.reset();
        ResponseStatic.reset();

        try {
            processRequest(context);
        } catch (e:Dynamic) {
            clearRequestContext();
            throw e;
        }
        clearRequestContext();
    }

    private static function clearRequestContext():Void {
        RequestStatic.reset();
        ResponseStatic.clear();
    }

    private static function processRequest(context:IDriverContext):Void {
        var request:Request = null;
        var response:Response = null;
        var middlewares:Array<AbstractMiddleware> = [];
        try {
            try {
                request = context.buildRequest();
            } catch (e:Exception) {
                request = new BadRequest(e);
                request.context = context;
            }
            RequestStatic.set(request);

            // WebSocket upgrade detection
            var wsUpgradeHandler:AbstractWebSocketHandler = null;
            var routeData:Null<{route:RouteElement, params:Map<String, String>}> = null;

            var upgradeHeader = request.header("Upgrade");
            if(upgradeHeader != null && upgradeHeader.toLowerCase() == "websocket") {
                var wsRouteData = Route.resolveWebSocket(request.path, request.host);
                if(wsRouteData != null) {
                    var wsHandler = wsRouteData.route.getWsHandler();
                    if(wsHandler != null) {
                        wsUpgradeHandler = wsHandler;
                        routeData = wsRouteData;
                    }
                }
                // No WS route found, fall through to 404
            }

            if(routeData == null)
                routeData = Route.resolveRequest(request);

            if(routeData == null)
            {
                if(request.method != null && request.method.toUpperCase() != "OPTIONS") {
                    var allowedMethods = Route.allowedMethods(request);
                    if(allowedMethods.length > 0) {
                        ResponseStatic.header("Allow", allowedMethods.join(", "));
                        abort(405);
                    }
                }

                routeData = {route: publicRouteElement(), params: new Map()};
            }

            var routerElement = routeData.route;

            if (!routerElement.getStream() && !(request is BadRequest) && wsUpgradeHandler == null) {
                request.context.parseBody();
            }

            request.routeParameters = routeData.params ?? new Map();
            request.setAttribute(AttributeType.RouteElement, routerElement);

            var middlewareClasses:Array<Class<AbstractMiddleware>> = HxWell.middlewares.concat(@:privateAccess routerElement.middlewares);
            request.setAttribute(AttributeType.MiddlewareClasses, middlewareClasses);

            if(request is BadRequest) {
                var badRequest:BadRequest = cast request;
                throw new AbortException(#if debug 500 #else 400 #end, badRequest.e);
            }

            var middlewareIndex = 0;
            var executeMiddleware:Request->Null<Response> = null;

            executeMiddleware = function(req:Request):Null<Response> {
                if (middlewareIndex >= middlewareClasses.length) {
                    if(wsUpgradeHandler != null) {
                        context.upgradeToWebSocket(req, wsUpgradeHandler);
                        return null;
                    }

                    return executeHandler(req, routerElement);
                }

                var currentMiddlewareClass = middlewareClasses[middlewareIndex];
                var currentMiddleware = Type.createInstance(currentMiddlewareClass, []);
                middlewares.push(currentMiddleware);
                middlewareIndex++;

                return currentMiddleware.handle(req, executeMiddleware);
            };

            response = executeMiddleware(request);
            if (response != null) {
                context.writeResponse(response);
            }

        } catch (e:AbortException) {
            handleAbortException(request, e);

        } catch (e:Exception) {
            var abort = new AbortException(500, e);
            handleAbortException(request, abort);
            trace(e, CallStack.toString(e.stack));
        }

        // Cleanup resources
        disposeMiddlewares(middlewares);

        // Close the context if it is not a ManualResponse
        if(!Std.isOfType(response, AsyncResponse) && context != null)
        {
            context.close();
        }else{
            request.setAttribute("is_async_response", true);
        }
    }

    public static function authorizeWebSocket(request:Request, routerElement:RouteElement):Bool
    {
        var middlewares:Array<AbstractMiddleware> = [];
        var reachedHandler:Bool = false;

        try {
            var middlewareClasses:Array<Class<AbstractMiddleware>> = HxWell.middlewares.concat(@:privateAccess routerElement.middlewares);
            request.setAttribute(AttributeType.MiddlewareClasses, middlewareClasses);

            var middlewareIndex = 0;
            var executeMiddleware:Request->Null<Response> = null;

            executeMiddleware = function(req:Request):Null<Response> {
                if (middlewareIndex >= middlewareClasses.length) {
                    reachedHandler = true;
                    return null;
                }

                var currentMiddlewareClass = middlewareClasses[middlewareIndex];
                var currentMiddleware = Type.createInstance(currentMiddlewareClass, []);
                middlewares.push(currentMiddleware);
                middlewareIndex++;

                return currentMiddleware.handle(req, executeMiddleware);
            };

            if (executeMiddleware(request) != null)
                reachedHandler = false;
        } catch (e:Dynamic) {
            trace('WebSocket authorization failed for ${request.path}: ${Std.string(e)}');
            reachedHandler = false;
        }

        disposeMiddlewares(middlewares);

        return reachedHandler;
    }

    private static function executeHandler(request:Request, routerElement:RouteElement):Null<Response> {
        var handler = routerElement.getHandler();
        var wsHandler = routerElement.getWsHandler();

        // TODO: Move this hack
        if(request.context.input is SocketInput)
            cast(request.context.input, SocketInput).length = Std.parseInt(request.header("Content-Length", "0"));

        if(handler != null) {
            if(!routerElement.getStream()) {
                if(!handler.validate()) {
                    abort(422);
                }
            }
            #if debug
        trace('${request.method} ${request.path}, stream: ${routerElement.getStream()}');
        #end
            return handler.execute(request);
        } else if(wsHandler != null) {
            #if debug
			trace('${request.method} ${request.path} (WebSocket HTTP fallback)');
			#end
            if(request.method.toUpperCase() == "GET") {
                var response = wsHandler.onGet(request);
                if(response == null)
                    abort(404);
                return response;
            } else if(request.method.toUpperCase() == "POST") {
                var response = wsHandler.onPost(request);
                if(response == null)
                    abort(404);
                return response;
            }
        }

        abort(404);
        return null;
    }

    private static var fallbackRouteElement:RouteElement;

    private static function publicRouteElement():RouteElement {
        if(fallbackRouteElement == null) {
            var routeElement = new RouteElement();
            routeElement.handler(Route.publicHandler);
            @:privateAccess routeElement.routePattern = new RoutePattern("");
            fallbackRouteElement = routeElement;
        }

        return fallbackRouteElement;
    }

    private static function disposeMiddlewares(middlewares:Array<AbstractMiddleware>):Void
    {
        while (middlewares.length > 0) {
            try {
                middlewares.pop().dispose();
            } catch (e:Dynamic) {
                trace(e);
            }
        }
    }
}
