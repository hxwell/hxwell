package hx.well.handler;

import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.validator.ValidatorRule;

class ApiHandler extends MethodHandler {
    @:post
    @:validator("name", [ValidatorRule.Required])
    public function check(request:Request):AbstractResponse {
        return "valid:" + request.input("name");
    }
}
