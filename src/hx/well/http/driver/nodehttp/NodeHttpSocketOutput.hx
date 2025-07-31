package hx.well.http.driver.nodehttp;

#if js
import haxe.io.Output;
import js.node.http.ServerResponse;
import js.node.buffer.Buffer;
import haxe.io.Bytes;
import haxe.io.Error;
import haxe.extern.EitherType;

class NodeHttpSocketOutput extends Output {
    private var serverResponse:ServerResponse;

    public function new(serverResponse:ServerResponse) {
        this.serverResponse = serverResponse;
    }

    public override function writeByte(c:Int):Void {
        writeSync(Buffer.from([c]));
    }

    public override function writeBytes(s:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > s.length)
			throw Error.OutsideBounds;
        writeSync(Buffer.hxFromBytes(s.sub(pos, len)));
        return len;
    }

    function writeSync(chunk:Dynamic, ?encoding:String, ?callback:EitherType<Void->Void, Null<Error>->Void>) {
        var done = false;
        var result = null;

        // res.write() false dönerse drain bekle
        function tryWrite() {
            var canWrite = serverResponse.write(chunk, encoding, callback);
            if (!canWrite) {
                // Buffer doldu, drain bekle
                serverResponse.once('drain', () -> {
                    done = true;
                });
            } else {
                // Yazma tamamlandı
                done = true;
            }
        }

        tryWrite();

        sys.NodeSync.wait(() -> done);
    }


    public override function close():Void {

    }
}
#end