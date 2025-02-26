package hx.well.route;
import hx.well.services.AbstractService;
import haxe.http.HttpMethod;
import hx.well.route.RouteElement;
import haxe.io.Path;
import hx.well.tools.AbstractEnumTools;
import hx.well.middleware.AbstractMiddleware;
using StringTools;

@:allow(hx.well.route.Route)
class RouteElement {
    public static var groups:Array<RouteGroupElement> = [];

    private var __routeType:RouteType;
    private var _name:String;
    private var methods:Array<HttpMethod> = [HttpMethod.Get];
    private var routePattern:RoutePattern;
    private var routePath(default, null):String;
    public var value(default, null):String;
    private var serviceHandler:AbstractService;
    private var stream:Bool;
    private var middlewares:Array<Class<AbstractMiddleware>> = [];
    private var _where:Map<String, String> = new Map();

    public function new() {
        for(group in groups)
            middlewares = middlewares.concat(group.middlewares);
    }

    public function get():RouteElement {
        this.setMethod(HttpMethod.Get);
        return this;
    }

    public function post():RouteElement {
        this.setMethod(HttpMethod.Post);
        return this;
    }

    public function put():RouteElement {
        this.setMethod(HttpMethod.Put);
        return this;
    }

    public function delete():RouteElement {
        this.setMethod(HttpMethod.Delete);
        return this;
    }

    public function patch():RouteElement {
        this.setMethod(HttpMethod.Patch);
        return this;
    }

    public function head():RouteElement {
        this.setMethod(HttpMethod.Head);
        return this;
    }

    public function options():RouteElement {
        this.setMethod(HttpMethod.Options);
        return this;
    }

    public function trace():RouteElement {
        this.setMethod(HttpMethod.Trace);
        return this;
    }

    public function connect():RouteElement {
        this.setMethod(HttpMethod.Connect);
        return this;
    }

    public function any():RouteElement {
        this.setMethods(AbstractEnumTools.getValues(HttpMethod));
        return this;
    }

    public function match(methods:Array<HttpMethod>):RouteElement {
        this.setMethods(methods);
        return this;
    }

    public function method(method:HttpMethod):RouteElement {
        this.setMethod(method);
        return this;
    }

    public function getMethods():Array<HttpMethod> {
        return methods;
    }

    public function setMethods(methods:Array<HttpMethod>):RouteElement {
        this.methods = methods;
        return this;
    }

    public function middleware(middlewares:Array<Class<AbstractMiddleware>>):RouteElement {
        this.middlewares = this.middlewares.concat(middlewares);
        return this;
    }

    public function group(callback:Void->Void):Void
    {
        Route.routes.remove(this);

        if(_name != null)
            Route.routeByName.remove(_name);

        var group:RouteGroupElement = new RouteGroupElement();
        group.name = this._name;
        group.path = this.routePath;
        group.middlewares = middlewares;
        RouteElement.groups.push(group);
        callback();
        RouteElement.groups.pop();
    }

    public function setMethod(method:HttpMethod):RouteElement {
        return setMethods([method]);
    }

    public function path(path:String):RouteElement {
        if(path.endsWith("/"))
            path = path.substring(0, path.lastIndexOf("/"));

        if(!path.startsWith("/"))
            path = "/" + path;

        this.__routeType = PATH;
        // Add group paths
        var fullPath = "";
        for (group in groups) {
            fullPath += group.path;
        }
        fullPath += path;
        this.routePath = path;
        this.value = fullPath;
        this.routePattern = new RoutePattern(fullPath);
        return this;
    }

    public function status(code:Int):RouteElement {
        this.value = code + "";
        this.__routeType = RouteType.STATUS_CODE;
        return this;
    }

    public inline function getHandler():AbstractService {
        return serviceHandler;
    }

    public function handler(handler:AbstractService):RouteElement {
        this.serviceHandler = handler;
        return this;
    }

    public inline function getStream():Bool {
        return stream;
    }

    public function setStream(stream:Bool):RouteElement {
        this.stream = stream;
        return this;
    }

    public function name(name:String):RouteElement {
        var prefix = "";
        for(group in groups)
            prefix += group.name ?? "";

        name = prefix + name;

        if(Route.routeByName.exists(name))
            throw '${name} named route already exists.';

        // Remove old
        Route.routeByName.remove(_name);

        // Create new
        Route.routeByName.set(name, this);
        this._name = name;
        return this;
    }

    public function where(param:String, pattern:String, opt:String = "i"):RouteElement {
        _where.set(param, pattern);
        routePattern.addConstraint(param, pattern);
        return this;
    }

    public function matches(path:String):Null<Map<String, String>> {
        return routePattern.match(path);
    }
}
