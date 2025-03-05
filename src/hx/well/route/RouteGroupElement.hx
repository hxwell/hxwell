package hx.well.route;
import hx.well.middleware.AbstractMiddleware;
class RouteGroupElement {
    public var name:String;
    public var path:String;
    public var middlewares:Array<Class<AbstractMiddleware>> = [];
    public var routeDomainPattern:RoutePattern;

    public function new() {

    }
}
