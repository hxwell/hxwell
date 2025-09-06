package hx.well.middleware;

import hx.well.middleware.AbstractMiddleware;
import hx.well.http.Response;
import hx.well.http.Request;
import hx.well.http.ResponseBuilder;
import hx.well.http.encoding.DeflateEncodingOptions;

class EncodeMiddleware extends AbstractMiddleware {
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        trace(EncodeMiddleware);

        var response:Response = ResponseBuilder.asStatic();
        response.encodingOptions = new DeflateEncodingOptions(1, 64 * 1024);

        return next(request);
    }
}