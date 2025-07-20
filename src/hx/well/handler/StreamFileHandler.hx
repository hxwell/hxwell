package hx.well.handler;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import sys.io.File;
import hx.well.http.Response;

class StreamFileHandler extends AbstractHandler {
    private var path:String;
    private var code:Null<Int>;

    public function new(path:String, code:Null<Int> = null):Void
    {
        super();
        this.path = path;
        this.code = code;
    }

    public function execute(request:Request):AbstractResponse {
        var abstractResponse:AbstractResponse = File.read('${path}');
        var response:Response = abstractResponse;
        response.statusCode = code;
        return response;
    }
}