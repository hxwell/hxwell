package hx.well.handler;
import hx.well.http.Request;
import sys.net.Socket;
import hx.well.http.AbstractResponse;

class DynamicHandler extends AbstractHandler {
    private var callback:Request->AbstractResponse;

    public function new(callback:Request->AbstractResponse) {
        super();
        this.callback = callback;
    }

    public function execute(request:Request):AbstractResponse {
        return callback(request);
    }
}