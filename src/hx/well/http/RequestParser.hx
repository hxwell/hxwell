package hx.well.http;
import hx.well.http.ResponseStatic.ResponseStatic.abort;
import hx.well.facades.Config;
using StringTools;

class RequestParser {
    public static function parseCookies(cookieHeader:String):Map<String, String> {
        var cookies:Map<String, String> = new Map<String, String>();
        if(cookieHeader == null)
            return cookies;

        for (part in cookieHeader.split(";")) {
            part = part.trim();
            var valueIndex = part.indexOf("=");
            if(valueIndex == -1)
                continue;

            var key = part.substring(0, valueIndex);
            var value = part.substring(valueIndex + 1);
            if(value != "")
                cookies.set(key, value);
        }
        return cookies;
    }

    public static function parseQueryString(path:String):Map<String, String> {
        var params = new Map<String, String>();
        var queryIndex = path.indexOf("?");

        if (queryIndex != -1) {
            var queryString = path.substr(queryIndex + 1);
            var pairs = queryString.split("&");

            for (pair in pairs) {
                var separator = pair.indexOf("=");
                if (separator != -1) {
                    params.set(
                        pair.substring(0, separator).urlDecode(),
                        pair.substring(separator + 1).urlDecode()
                    );
                }
            }
        }

        return params;
    }

    public static function isBodyAvailable(request:Request):Bool {
        return request.header("Content-Length") != null;
    }

    public static function contentLength(value:String):Int {
        if(value == null) return 0;
        if(value.length == 0) abort(400);
        var result = 0;
        for(i in 0...value.length) {
            var digit = value.charCodeAt(i) - 48;
            // Check before multiplication: parsing must not wrap or accept a prefix.
            if(digit < 0 || digit > 9 || result > 214748364 || (result == 214748364 && digit > 7))
                abort(400);
            result = result * 10 + digit;
        }
        return result;
    }

    /** Raw Socket supports fixed-length bodies only; never guess framing. */
    public static function validateSocketFraming(request:Request):Int {
        var lengthHeader = request.header("Content-Length");
        if(request.header("Transfer-Encoding") != null) {
            if(lengthHeader != null) abort(400);
            abort(501);
        }
        var length = contentLength(lengthHeader);
        var maximumContentLength:Int = Config.get("http.max_content_length");
        if(length > maximumContentLength) abort(413);
        return length;
    }

    public static function parseFromRawRequest(rawRequest: String): Request {
        var lines = rawRequest.split("\r\n");
        var requestLine = lines[0].split(" ");
        if(requestLine.length != 3 || !HttpSyntax.isToken(requestLine[0])
            || requestLine[1].length == 0 || !HttpSyntax.isFieldValue(requestLine[1])
            || requestLine[1].indexOf("\t") != -1
            || (requestLine[2] != "HTTP/1.1" && requestLine[2] != "HTTP/1.0"))
            abort(400);
        var method = requestLine[0];
        var target = requestLine[1];
        var queryIndex = target.indexOf("?");
        var path = (queryIndex == -1 ? target : target.substring(0, queryIndex)).urlDecode();
        var maximumPathLength:Int = Config.get("http.max_path_length");
        if(target.length > maximumPathLength || path.length > maximumPathLength)
            abort(414);

        var version = requestLine[2];
        var headers = new Map<String, String>();
        for (i in 1...lines.length) {
            var separator = lines[i].indexOf(":");
            if(separator <= 0) abort(400);
            var name = lines[i].substring(0, separator);
            var value = HttpSyntax.trimOWS(lines[i].substring(separator + 1));
            if(!HttpSyntax.isToken(name) || !HttpSyntax.isFieldValue(value)) abort(400);
            name = HttpSyntax.lowerAscii(name);
            if(headers.exists(name)) {
                if(name == "content-length" || name == "transfer-encoding" || name == "host") abort(400);
                value = headers.get(name) + (name == "cookie" ? "; " : ", ") + value;
            }
            headers.set(name, value);
        }

        var cookies:Map<String, String> = parseCookies(headers.get("cookie"));

        if(!headers.exists("host") || headers.get("host") == "")
            abort(400);

        var host:String = headers.get("host");
        var request:Request = new Request();
        request.host = host;
        request.method = method;
        request.path = path;
        request.queries = parseQueryString(target);
        request.version = version;
        request.headers = headers;
        request.cookies = cookies;
        validateSocketFraming(request);
        return request;
    }
}
