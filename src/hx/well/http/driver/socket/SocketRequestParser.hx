package hx.well.http.driver.socket;
import sys.net.Socket;
import haxe.io.Input;
import haxe.io.Bytes;
import hx.well.facades.Config;
import hx.well.http.ResponseStatic.abort;
import hx.well.http.Request;
using StringTools;

class SocketRequestParser {
    private static var httpRequestEnd = [0x0D, 0x0A, 0x0D, 0x0A];

    #if (!php && !js)
    public static function parseFromSocket(socket:Socket):Request
    {
        var requestBytes:Bytes = parseFromInputProtocol(socket.input);
        var request:Request = RequestParser.parseFromRawRequest(requestBytes.toString());
        request.requestBytes = requestBytes;
        request.ip = socket.peer().host.toString();
        return request;
    }
    #end

    public static function parseBody(request:Request, input:Input):Void
    {
        if(request.headers.exists("Content-Length") && request.headers.get("Content-Length") != "0")
        {
            var maximumContentLength:Int = Config.get("header.max_content_length", 1048576);
            var contentLength = Std.parseInt(request.headers.get("Content-Length"));
            if(contentLength > maximumContentLength) {
                abort(413);
            }

            var bodyBytes:Bytes = input.read(contentLength);
            request.bodyBytes = bodyBytes;
            request._parsedBody = RequestBodyParser.fromBodyBytes(bodyBytes);
        }else{
            request.bodyBytes = Bytes.alloc(0);
        }
    }

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
}
