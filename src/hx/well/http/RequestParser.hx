package hx.well.http;
import sys.net.Socket;
import haxe.io.Input;
import haxe.io.Bytes;
import hx.well.facades.Config;
import hx.well.http.ResponseStatic.abort;
using StringTools;

class RequestParser {
    private static var httpRequestEnd = [0x0D, 0x0A, 0x0D, 0x0A];

    #if !php
    public static function parseFromSocket(socket:Socket):Request
    {
        var requestBytes:Bytes = parseFromInputProtocol(socket.input);
        var request:Request = RequestParser.parseFromRawRequest(requestBytes.toString());
        request.requestBytes = requestBytes;
        request.socket = socket;
        return request;
    }
    #end

    #if !php
    private static function parseFromInputProtocol(input:Input):Bytes
    {
        var maximumHeaderBuffer:Int = Config.get("header.max_buffer", 8192);

        #if cpp
        var buffer:Array<cpp.UInt8> = new Array<cpp.UInt8>();
        #elseif java
        var buffer:Array<java.lang.Byte> = new Array<java.lang.Byte>();
        #else
        var buffer:Array<Int> = new Array<Int>();
        #end
        var index:Int = 0;
        while (true)
        {
            var found:Bool = false;
            buffer[index] = input.readByte();
            if (index >= 4)
            {
                found = true;
                for(i in 0...4)
                {
                    if(buffer[index - 3 + i] != httpRequestEnd[i])
                    {
                        found = false;
                        break;
                    }
                }
            }
            index++;

            if(found)
                break;

            if(buffer.length > maximumHeaderBuffer)
            {
                abort(431);
            }
        }

        buffer.resize(buffer.length - httpRequestEnd.length);

        #if cpp
        return Bytes.ofData(buffer);
        #else
        var bytes = Bytes.alloc(buffer.length);
        for(i in 0...buffer.length)
        {
            bytes.set(i, cast buffer[i]);
        }
        return bytes;
        #end
    }
    #end

    public static function parseFromRawRequest(rawRequest: String): Request {
        var lines = rawRequest.split("\r\n");
        var requestLine = lines[0].split(" ");
        #if debug
        trace(requestLine);
        #end
        var method = requestLine[0];
        var path = requestLine[1].urlDecode();
        var maximumPathLength:Int = Config.get("header.max_path_length", 2048);
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
                var keyValue = part.split("=");
                if (keyValue.length == 2) {
                    cookies.set(keyValue[0], keyValue[1]);
                }
            }
        }

        // Parse body
        var body = "";
        if (headers.exists("Content-Length")) {
            var contentLength = Std.parseInt(headers.get("Content-Length"));
            var bodyStart = rawRequest.indexOf(requestLine[3] ?? "") + 4;
            body = rawRequest.substr(bodyStart, contentLength);
        }

        if(!headers.exists("Host"))
            abort(400);

        var host:String = headers.get("Host");
        if(host.contains(":"))
            host = host.substr(0, host.lastIndexOf(":"));

        var request:Request = new Request();
        request.host = host;
        request.method = method;
        request.path = path;
        request.version = version;
        request.headers = headers;
        request.cookies = cookies;
        return request;
    }

    public static function isBodyAvailable(request:Request):Bool {
        return request.headers.exists("Content-Length");
    }

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
}
