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
        if(length <= 0) throw new haxe.io.Eof();
        var value = socket.input.readByte();
        length--;
        return value;
    }

    public override function readBytes(s:Bytes, pos:Int, len:Int):Int {
        #if !neko
        if (pos < 0 || len < 0 || pos + len > s.length)
            throw Error.OutsideBounds;
        #end

        if(len == 0) return 0;
        if(length <= 0) throw new haxe.io.Eof();
        var bytesRead = socket.input.readBytes(s, pos, len < length ? len : length);
        length -= bytesRead;
        return bytesRead;
    }

    public function clear():Void {
        var buffer = Bytes.alloc(1024);
        while(length > 0)
            if(readBytes(buffer, 0, buffer.length) == 0) throw new haxe.io.Eof();
    }
}
