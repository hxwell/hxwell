package hx.well.service;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.redirect;
class RedirectService extends AbstractService {
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