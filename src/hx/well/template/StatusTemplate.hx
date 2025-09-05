package hx.well.template;
import hx.well.handler.AbstractHandler;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import haxe.Resource;
import haxe.Template;
import hx.well.http.ResponseStatic;
import hx.well.http.ResponseBuilder;

class StatusTemplate extends AbstractHandler {
    private var statusCode:Int;

    public function new(statusCode:Int) {
        super();

        this.statusCode = statusCode;
    }

    public function execute(request:Request):AbstractResponse {
        return ResponseBuilder.asTemplate("status", {
            code: statusCode,
            message: ResponseStatic.getStatusMessage(statusCode),
        });
    }
}