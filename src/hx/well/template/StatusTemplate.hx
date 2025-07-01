package hx.well.template;

import hx.well.service.AbstractService;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.response;
import haxe.Resource;
import haxe.Template;
import hx.well.http.ResponseStatic;

class StatusTemplate extends AbstractService {
    private static var template:Template = new Template(Resource.getString("internal/template/status.template.html"));

    private var statusCode:Int;

    public function new(statusCode:Int) {
        super();

        this.statusCode = statusCode;
    }

    public function execute(request:Request):AbstractResponse {
        return response().asTemplate(template, {
            code: statusCode,
            message: ResponseStatic.getStatusMessage(statusCode),
        });
    }
}