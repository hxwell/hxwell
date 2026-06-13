package hx.well.provider;

import hx.well.route.Route;
import hx.well.handler.AbortHandler;
import hx.well.handler.ApiHandler;
import hx.well.websocket.EchoWebSocketHandler;
import hx.well.http.JsonResponse;
import hx.well.http.Response;
import hx.well.http.ResponseStatic;
import hx.well.http.AbstractResponse;
import hx.well.http.encoding.DeflateEncodingOptions;

using hx.well.tools.RouteElementTools;

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

        Route.any("/api/{method}").handler(new ApiHandler());

        Route.get("/session/set/{value}", request -> {
            request.session.put("stored", request.route("value"));
            return ("stored" : AbstractResponse);
        });

        Route.get("/session/get", request ->
            "value:" + (request.session.get("stored") ?? "none"));

        Route.get("/deflate", request -> {
            var response:Response = ("deflate-payload-deflate-payload-deflate-payload" : AbstractResponse);
            response.encodingOptions = new DeflateEncodingOptions(6, 64 * 1024);
            return (response : AbstractResponse);
        });

        Route.get("/keep", request -> {
            var response:Response = ("keep" : AbstractResponse);
            response.header("Connection", "keep-alive");
            return (response : AbstractResponse);
        });

        Route.get("/stream").file("public/sample.txt");

        Route.websocket("/ws").handler(new EchoWebSocketHandler());
    }
}
