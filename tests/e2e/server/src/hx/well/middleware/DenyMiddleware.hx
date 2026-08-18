package hx.well.middleware;

import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseBuilder;

class DenyMiddleware extends AbstractMiddleware {
    public function new() {
        super();
    }

    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        return ResponseBuilder.asString("denied", 403);
    }
}
