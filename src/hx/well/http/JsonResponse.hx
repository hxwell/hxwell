package hx.well.http;

class JsonResponse extends Response {
    public var data:Dynamic;

    public function new(data:Dynamic, statusCode:Null<Int> = null) {
        super();

        this.data = data;
        header("Content-Type", "application/json");
    }

    public override function toString():String
    {
        return haxe.Json.stringify(data, (key, value) -> {
            if(value is IResponseInstance)
            {
                var response = cast(value, IResponseInstance).getResponse();
                if(response is JsonResponse)
                    return cast(response, JsonResponse).data;
            }
            return value;
        });
    }
}
