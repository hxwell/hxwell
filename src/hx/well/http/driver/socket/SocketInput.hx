package hx.well.http.driver.socket;
import haxe.io.Bytes;
import sys.net.Socket;
import haxe.io.Input;
#if !neko
import haxe.io.Error;
#end

class SocketInput extends Input {
    private var socket:Socket;
    public var length:Int = 0;

    public function new(socket:Socket) {
        this.socket = socket;
    }

    public override function readByte():Int {
        length--;
        return socket.input.readByte();
    }

    public override function readBytes(s:Bytes, pos:Int, len:Int):Int {
        #if !neko
        if (pos < 0 || len < 0 || pos + len > s.length)
            throw Error.OutsideBounds;
        #end

        var bytesRead = socket.input.readBytes(s, pos, len);
        length -= bytesRead;
        return bytesRead;
    }

    public function clear():Void {
        trace('Clearing remaining input: ' + length + ' bytes');
        if(length > 0) {
            while(length > 0) {
                var toRead = Std.int(Math.min(length, 1024));
                socket.input.read(toRead);
                length -= toRead;
            }
        }
    }
}
