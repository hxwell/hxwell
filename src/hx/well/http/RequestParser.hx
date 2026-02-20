package hx.well.http;
import hx.well.http.ResponseStatic.ResponseStatic.abort;
import hx.well.facades.Config;
using StringTools;

class RequestParser {
    public static function parseQueryString(path:String):Map<String, String> {
        var params = new Map<String, String>();
        var queryIndex = path.indexOf("?");

        if (queryIndex != -1) {
            var queryString = path.substr(queryIndex + 1);
            var pairs = queryString.split("&");

            for (pair in pairs) {
                var parts = pair.split("=");
                if (parts.length == 2) {
                    params.set(
                        parts[0].urlDecode(),
                        parts[1].urlDecode()
                    );
                }
            }
        }

        return params;
    }

    public static function isBodyAvailable(request:Request):Bool {
        return request.headers.exists("Content-Length");
    }

    public static function parseFromRawRequest(rawRequest: String): Request {
        var lines = rawRequest.split("\r\n");
        var requestLine = lines[0].split(" ");
        #if debug
        trace(requestLine);
        #end
        var method = requestLine[0];
        var path = requestLine[1].urlDecode();
        var maximumPathLength:Int = Config.get("http.max_path_length");
        if(path.length > maximumPathLength)
            abort(414);

        var version = requestLine[2];
        var headers = new Map<String, String>();
        for (i in 1...lines.length) {
            var header = lines[i].split(": ");
            if (header.length == 2) {
                headers.set(header[0], header[1]);
            }
        }

        var cookies:Map<String, String> = new Map<String, String>();
        if(headers.exists("Cookie"))
        {
            var cookieData:String = headers.get("Cookie");
            var parts:Array<String> = cookieData.split(";");

            for (part in parts) {
                part = part.trim();
                var valueIndex = part.indexOf("=");
                var key = part.substring(0, valueIndex);
                var value = part.substring(valueIndex + 1);
                if(value != "") {
                    cookies.set(key, value);
                }
            }
        }

        // Parse body
        var body = "";
        if (headers.exists("Content-Length")) {
            var contentLength = Std.parseInt(headers.get("Content-Length"));
            var bodyStart = rawRequest.indexOf(requestLine[3] ?? "") + 4;
            body = rawRequest.substr(bodyStart, Std.int(Math.min(contentLength, rawRequest.length - bodyStart)));
        }

        if(!headers.exists("Host"))
            abort(400);

        var host:String = headers.get("Host");
        var request:Request = new Request();
        request.host = host;
        request.method = method;
        request.path = path;
        request.version = version;
        request.headers = headers;
        request.cookies = cookies;
        return request;
    }
}
