package hx.well.middleware;

import hx.well.middleware.AbstractMiddleware;
import hx.well.http.Response;
import hx.well.http.Request;
import hx.well.http.ResponseBuilder;

class SampleMiddleware extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        ResponseBuilder.asStatic().header("Sample-Middleware", "SampleValue");

        return next(request);
    }
}
