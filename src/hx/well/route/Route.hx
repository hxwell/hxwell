package hx.well.route;
import haxe.http.HttpMethod;
import hx.well.route.RouteElement;
import hx.well.http.Request;
import hx.well.tools.AbstractEnumTools;
import hx.well.middleware.AbstractMiddleware;
import hx.well.handler.PublicHandler;
import hx.well.handler.AbstractHandler;
import hx.well.handler.DynamicHandler;
import hx.well.http.AbstractResponse;
using StringTools;
class Route {
    public static var routes:Array<RouteElement> = [];
    public static var routeByName:Map<String, RouteElement> = new Map();
    public static var publicHandler:AbstractHandler = new PublicHandler();

    public static function log():Void
    {
        for(route in routes)
        {
            if(route.__routeType == RouteType.PATH)
            {
                if(route._name != null) {
                    trace('${route._name} - ${route.getMethods()} - ${route.value} service registered.');
                }else{
                    trace('${route.getMethods()} - ${route.value} service registered.');
                }
            } else if(route.__routeType == RouteType.WEBSOCKET) {
                if(route._name != null) {
                    trace('${route._name} - WS - ${route.value} websocket registered.');
                } else {
                    trace('WS - ${route.value} websocket registered.');
                }
            }
        }
    }

    public static function resolveRequest(httpRequest:Request):Null<{route:RouteElement, params:Map<String, String>}> {
        var path:String = httpRequest.path;
        if(path.endsWith("/")) {
            path = path.substring(0, path.lastIndexOf("/"));
        }

        for (route in routes) {
            if(route.__routeType != RouteType.PATH && route.__routeType != RouteType.WEBSOCKET)
                continue;

            var params = route.matches(path);
            if (params != null && route.getMethods().contains(httpRequest.method)) {
                var hostWithoutPort = httpRequest.host.split(":")[0];
                var routeDomainPattern = route.routeDomainPattern == null ? null : route.routeDomainPattern.match(hostWithoutPort);
                if(route.routeDomainPattern != null && routeDomainPattern == null)
                    continue;

                if(routeDomainPattern != null) {
                    for(keyValueIterator in routeDomainPattern.keyValueIterator())
                        params.set(keyValueIterator.key, keyValueIterator.value);
                }

                return {route: route, params: params};
            }
        }

        return null;
    }

    public static function resolveWebSocket(path:String):Null<{route:RouteElement, params:Map<String, String>}> {
        if(path.endsWith("/")) {
            path = path.substring(0, path.lastIndexOf("/"));
        }

        for(route in routes) {
            if(route.__routeType != RouteType.WEBSOCKET)
                continue;

            var params = route.matches(path);
            if(params != null) {
                return {route: route, params: params};
            }
        }

        return null;
    }

    public static function allowedMethods(httpRequest:Request):Array<HttpMethod> {
        var path:String = httpRequest.path;
        if(path.endsWith("/")) {
            path = path.substring(0, path.lastIndexOf("/"));
        }

        var allowed:Array<HttpMethod> = [];
        for (route in routes) {
            if(route.__routeType != RouteType.PATH && route.__routeType != RouteType.WEBSOCKET)
                continue;

            if(route.matches(path) == null)
                continue;

            if(route.routeDomainPattern != null) {
                var hostWithoutPort = httpRequest.host == null ? "" : httpRequest.host.split(":")[0];
                if(route.routeDomainPattern.match(hostWithoutPort) == null)
                    continue;
            }

            for (method in route.getMethods()) {
                if(!allowed.contains(method))
                    allowed.push(method);
            }
        }

        return allowed;
    }

    public static function resolveStatusCode(code:String):RouteElement {
        for (route in routes) {
            if(route.__routeType != RouteType.STATUS_CODE)
                continue;

            if (route.value == code) {
                return route;
            }
        }

        return null;
    }

    public static overload extern inline function get(path:String):RouteElement {
        return method(HttpMethod.Get, path);
    }

    public static overload extern inline function get(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Get, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function get(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Get, path)._handler(handler);
    }

    public static overload extern inline function post(path:String):RouteElement {
        return method(HttpMethod.Post, path);
    }

    public static overload extern inline function post(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Post, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function post(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Post, path)._handler(handler);
    }

    public static overload extern inline function put(path:String):RouteElement {
        return method(HttpMethod.Put, path);
    }

    public static overload extern inline function put(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Put, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function put(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Put, path)._handler(handler);
    }

    public static overload extern inline function delete(path:String):RouteElement {
        return method(HttpMethod.Delete, path);
    }

    public static overload extern inline function delete(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Delete, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function delete(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Delete, path)._handler(handler);
    }

    public static overload extern inline function patch(path:String):RouteElement {
        return method(HttpMethod.Patch, path);
    }

    public static overload extern inline function patch(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Patch, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function patch(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Patch, path)._handler(handler);
    }

    public static overload extern inline function head(path:String):RouteElement {
        return method(HttpMethod.Head, path);
    }

    public static overload extern inline function head(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Head, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function head(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Head, path)._handler(handler);
    }

    public static overload extern inline function options(path:String):RouteElement {
        return method(HttpMethod.Options, path);
    }

    public static overload extern inline function options(path:String, callback:Request->AbstractResponse):RouteElement {
        return method(HttpMethod.Options, path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function options(path:String, handler:AbstractHandler):RouteElement {
        return method(HttpMethod.Options, path)._handler(handler);
    }

    public static function trace(path:String):RouteElement {
        return method(HttpMethod.Trace, path);
    }

    public static function connect(path:String):RouteElement {
        return method(HttpMethod.Connect, path);
    }

    public static overload extern inline function any(path:String):RouteElement {
        return match(AbstractEnumTools.getValues(HttpMethod), path);
    }

    public static overload extern inline function any(path:String, callback:Request->AbstractResponse):RouteElement {
        return match(AbstractEnumTools.getValues(HttpMethod), path)._handler(new DynamicHandler(callback));
    }

    public static overload extern inline function any(path:String, handler:AbstractHandler):RouteElement {
        return match(AbstractEnumTools.getValues(HttpMethod), path)._handler(handler);
    }

    private static function create():RouteElement {
        var routerElement = new RouteElement();
        routes.push(routerElement);
        return routerElement;
    }

    public static function name(name:String):RouteElement {
        return create()
            .name(name);
    }

    public static function domain(domain:String):RouteElement {
        return create()
            .domain(domain);
    }

    public static function path(path:String):RouteElement {
        return create()
            .path(path);
    }

    public static function redirect(url:String, destination:String, status:Int = 302):RouteElement {
        return create()
            .redirect(url, destination, status);
    }

    public static function permanentRedirect(url:String, destination:String):RouteElement {
        return create()
            .permanentRedirect(url, destination);
    }

    public static function match(methods:Array<HttpMethod>, path:String):RouteElement {
        return create()
            .setMethods(methods)
            .path(path);
    }

    public static function method(method:HttpMethod, path:String):RouteElement {
        if(path.endsWith("/")) {
            path = path.substring(0, path.lastIndexOf("/"));
        }

        return create()
            .setMethod(method)
            .path(path);
    }

    public static function websocket(path:String):RouteElement {
        return create().websocket(path);
    }

    public static function status(code:Int):RouteElement {
        return create()
            .any()
            .status(code);
    }

    public static function middleware(middlewares:Array<Class<AbstractMiddleware>>):RouteElement
    {
        return create()
            ._middleware(middlewares);
    }
}
