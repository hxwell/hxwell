package hx.well.tools;
import hx.well.route.RouteElement;
import hx.well.handler.StreamFileHandler;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.handler.DynamicHandler;

class RouteElementTools {
    public static function file(routeElement:RouteElement, path:String, code:Null<Int> = null):RouteElement {
        return routeElement.handler(new StreamFileHandler(path, code));
    }

    public static function handle(routeElement:RouteElement, callback:Request->AbstractResponse):RouteElement {
        return routeElement.handler(new DynamicHandler(callback));
    }

    public static function whereNumber(routeElement:RouteElement, param:String):RouteElement {
        return routeElement.where(param, "[0-9]+");
    }
}