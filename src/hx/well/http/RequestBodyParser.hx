package hx.well.http;
import haxe.ds.Either;
import haxe.Json;
import haxe.io.Bytes;
import hx.well.http.RequestStatic.header;
import hx.well.request.JsonRequestBody;
import hx.well.request.ParameterRequestBody;
import hx.well.request.AbstractRequestBody;

class RequestBodyParser {
    public static function fromBodyBytes(bodyBytes:Bytes):Null<AbstractRequestBody> {
        var parsedBody:AbstractRequestBody = null;
        if (bodyBytes == null || bodyBytes.length == 0) return null;

        var contentType = header("Content-Type", "").toLowerCase();

        try {
            if (contentType.indexOf("application/json") != -1) {
                parsedBody = new JsonRequestBody(bodyBytes);
            } else if (contentType.indexOf("application/x-www-form-urlencoded") != -1) {
                parsedBody = new ParameterRequestBody(bodyBytes);
            }
        } catch (e) {
            trace('Body parse error: ${e.message}');
            parsedBody = null;
        }

        return parsedBody;
    }
}
