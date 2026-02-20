package hx.well.route;
import haxe.http.HttpMethod;
import hx.well.route.RouteElement;
import hx.well.http.Request;
import hx.well.tools.AbstractEnumTools;
import hx.well.middleware.AbstractMiddleware;
import hx.well.handler.PublicHandler;
import hx.well.handler.AbstractHandler;
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
            }
        }
    }

    public static function resolveRequest(httpRequest:Request):Null<{route:RouteElement, params:Map<String, String>}> {
        var path:String = httpRequest.path;
        if(path.endsWith("/")) {
            path = path.substring(0, path.lastIndexOf("/"));
        }

        for (route in routes) {
            if(route.__routeType != RouteType.PATH)
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

    public static function get(path:String):RouteElement {
        return method(HttpMethod.Get, path);
    }

    public static function post(path:String):RouteElement {
        return method(HttpMethod.Post, path);
    }

    public static function put(path:String):RouteElement {
        return method(HttpMethod.Put, path);
    }

    public static function delete(path:String):RouteElement {
        return method(HttpMethod.Delete, path);
    }

    public static function patch(path:String):RouteElement {
        return method(HttpMethod.Patch, path);
    }

    public static function head(path:String):RouteElement {
        return method(HttpMethod.Head, path);
    }

    public static function options(path:String):RouteElement {
        return method(HttpMethod.Options, path);
    }

    public static function trace(path:String):RouteElement {
        return method(HttpMethod.Trace, path);
    }

    public static function connect(path:String):RouteElement {
        return method(HttpMethod.Connect, path);
    }

    public static function any(path:String):RouteElement {
        return match(AbstractEnumTools.getValues(HttpMethod), path);
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

    public static function status(code:Int):RouteElement {
        return create()
            .any()
            .status(code);
    }

    public static overload extern inline function middleware(middlewares:Array<AbstractMiddleware>):RouteElement
    {
        return create()
            .middleware(middlewares);
    }

    public static overload extern inline function middleware(middlewares:Array<Class<AbstractMiddleware>>):RouteElement
    {
        return create()
            .middleware(middlewares);
    }
}