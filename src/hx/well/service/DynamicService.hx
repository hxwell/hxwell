package hx.well.service;
import hx.well.http.Request;
import sys.net.Socket;
import hx.well.http.AbstractResponse;
class DynamicService extends AbstractService {
    private var callback:Request->AbstractResponse;

    public function new(callback:Request->AbstractResponse) {
        super();
        this.callback = callback;
    }

    public function execute(request:Request):AbstractResponse {
        return callback(request);
    }
}