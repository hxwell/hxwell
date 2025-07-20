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

@:access(hx.well.exception.AbortException)
class HttpHandler {
    public static function handleAbortException(request:Request, exception:AbortException):Void
    {
        try {
            if(exception.statusCode == 500) {
                if(exception.parent == null) {
                    request.attributes.set(AttributeType.Exception, exception);
                } else {
                    request.attributes.set(AttributeType.Exception, exception.parent);
                }
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
        RequestStatic.set(null);
        ResponseStatic.reset();

        var request:Request = null;
        var response:Response = null;
        var middlewares:Array<AbstractMiddleware> = [];
        try {
            try {
                request = context.buildRequest();
            } catch (e:Exception) {
                throw new AbortException(500, e);
            }
            RequestStatic.set(request);

            var routeData = Route.resolveRequest(request);
            if(routeData == null)
            {
                var publicRouterElement = new RouteElement();
                publicRouterElement.handler(Route.publicHandler);
                @:privateAccess publicRouterElement.routePattern = new RoutePattern("");
                routeData = {route: publicRouterElement, params: new Map()};
            }

            var routerElement = routeData.route;
            request.routeParameters = routeData.params ?? new Map();
            request.attributes.set(AttributeType.RouteElement, routerElement);

            var middlewareClasses:Array<Class<AbstractMiddleware>> = HxWell.middlewares.concat(@:privateAccess routerElement.middlewares);
            request.attributes.set(AttributeType.MiddlewareClasses, middlewareClasses);

            var middlewareIndex = 0;
            var executeMiddleware:Request->Null<Response> = null;

            executeMiddleware = function(req:Request):Null<Response> {
                if (middlewareIndex >= middlewareClasses.length) {
                    return executeHandler(req, routerElement);
                }

                var currentMiddlewareClass = middlewareClasses[middlewareIndex];
                var currentMiddleware = Type.createInstance(currentMiddlewareClass, []);
                middlewares.push(currentMiddleware);
                middlewareIndex++;

                return currentMiddleware.handle(req, executeMiddleware);
            };

            var response = executeMiddleware(request);
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
        if(!Std.isOfType(response, ManualResponse) && context != null)
        {
            context.close();
        }
    }

    private static function executeHandler(request:Request, routerElement:RouteElement):Null<Response> {
        var handler = routerElement.getHandler();

        if (!routerElement.getStream()) {
            request.context.parseBody();

            if (!handler.validate()) {
                abort(404);
            }
        }
        #if debug
        trace('${request.method} ${request.path}, stream: ${routerElement.getStream()}');
        #end
        return handler.execute(request);
    }

    private static function disposeMiddlewares(middlewares:Array<AbstractMiddleware>):Void
    {
        while (middlewares.length > 0) {
            try {
                middlewares.shift().dispose();
            } catch (e:Exception) {
                trace(e);
            }
        }
    }
}