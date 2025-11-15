package hx.well.http.driver.socket;
import haxe.io.Output;
import haxe.io.Bytes;
import sys.net.Socket;
#if !neko
import haxe.io.Error;
#end

class SocketOutput extends Output {
    private var socket:Socket;

    public var isKeepAlive:Bool = false;
    public var isChunked:Bool = false;
    public var isClosed:Bool = false;

    public function new(socket:Socket) {
        this.socket = socket;
    }

    public override function writeByte(c:Int):Void {
        if(isChunked) {
            // Write Chunk Size
            socket.output.writeString('1\r\n');
        }

        // Write Data
        socket.output.writeByte(c);
        trace(c);

        if(isChunked)
            socket.output.writeString('\r\n');
    }

    public override function writeBytes(s:Bytes, pos:Int, len:Int):Int {
        //trace('SocketOutput.writeBytes: pos=' + pos + ', len=' + len);
        if(isChunked) {
            #if !neko
            if (pos < 0 || len < 0 || pos + len > s.length)
                throw Error.OutsideBounds;
            #end
            // Write Chunk Size
            socket.output.writeString(StringTools.hex(len) + '\r\n');
        }

        // Write Data
        socket.output.writeBytes(s, pos, len);

        if(isChunked)
            socket.output.writeString('\r\n');

        return len;
    }

    public override function flush():Void {
        socket.output.flush();
    }

    public override function close() {
        trace("close SocketOutput");
        if(isChunked) {
            // Write terminating chunk
            socket.output.writeString('0\r\n\r\n');
        }

        if(isKeepAlive) {
            socket.output.flush();
            trace("keep alive, not closing socket output");
        }else{
            try {
                socket.output.close();
            } catch (e:Dynamic) {

            }
        }

        socket = null;
        isClosed = true;
    }
}
