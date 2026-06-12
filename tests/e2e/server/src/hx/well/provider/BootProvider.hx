package hx.well.provider;

import hx.well.route.Route;
import hx.well.handler.AbortHandler;
import hx.well.http.JsonResponse;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.http.AbstractResponse;

class BootProvider extends AbstractProvider {
    public function boot():Void {
        Route.get("/multi/{a}/{b}/{c}", request ->
            request.route("a") + "-" + request.route("b") + "-" + request.route("c"));

        Route.get("/opt/{name?}", request -> "hello:" + (request.route("name") ?? "anon"));

        Route.get("/json", request -> new JsonResponse({hello: "world", n: 42}));

        Route.get("/headers", request -> {
            var response:Response = ("with-header" : AbstractResponse);
            response.header("X-Test-Header", "hxwell");
            return (response : AbstractResponse);
        });

        Route.get("/cookies", request -> {
            ResponseStatic.cookie("first", "1");
            ResponseStatic.cookie("second", "2");
            return ("two-cookies" : AbstractResponse);
        });

        Route.post("/echo", request -> "posted");

        Route.get("/abort/{code}")
            .handler(new AbortHandler())
            .where("code", "[1-5][0-9]{2}");
    }
}
