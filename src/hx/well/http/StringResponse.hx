package hx.well.http;

class StringResponse extends Response {
    public var body:String;

    public function new(body:String, statusCode:Null<Int> = null) {
        super(statusCode);
        this.body = body;
        this.header("Content-Type", "text/html");
    }

    public override function toString():String
    {
        return body;
    }
}
