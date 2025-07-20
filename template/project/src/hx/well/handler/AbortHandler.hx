package hx.well.handler;
import hx.well.handler.AbstractHandler;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.abort;

class AbortHandler extends AbstractHandler {

    public function execute(request:Request):AbstractResponse {
        trace("abort");
        abort(Std.parseInt(request.route("code")));
        return "";
    }
}