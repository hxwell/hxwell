package hx.well.tools;
import hx.well.route.RouteElement;
import hx.well.service.StreamFileService;
import hx.well.http.AbstractResponse;
import sys.net.Socket;
import hx.well.http.Request;
import hx.well.service.DynamicService;
class RouteElementTools {
    public static function file(routeElement:RouteElement, path:String, code:Null<Int> = null):RouteElement {
        return routeElement.handler(new StreamFileService(path, code));
    }

    public static function handle(routeElement:RouteElement, callback:Request->AbstractResponse):RouteElement {
        return routeElement.handler(new DynamicService(callback));
    }

    public static function whereNumber(routeElement:RouteElement, param:String):RouteElement {
        return routeElement.where(param, "[0-9]+");
    }
}