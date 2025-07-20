package hx.well.handler;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.redirect;

class RedirectHandler extends AbstractHandler {
    private var destination:String;
    private var status:Null<Int>;

    public function new(destination:String, status:Null<Int> = null) {
        super();
        this.destination = destination;
        this.status = status;
    }

    public function execute(request:Request):AbstractResponse {
        return redirect(destination, status);
    }
}