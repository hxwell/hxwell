package hx.well.http;
import haxe.Exception;
class BadRequest extends Request {
    public var e:Exception;

    public function new(e:Exception) {
        this.e = e;
        super();

        this.path = "/";
    }
}