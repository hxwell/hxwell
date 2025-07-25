package hx.well.zip;

#if java
import java.util.zip.Deflater;
import haxe.zip.FlushMode;

class Compress {
    var deflater:Deflater;
    var mode:Int;
    var finish:Bool = false;

    public function new(level:Int) {
        this.deflater = new Deflater(level);
        this.mode = Deflater.NO_FLUSH;
    }

    public function execute(src:haxe.io.Bytes, srcPos:Int, dst:haxe.io.Bytes, dstPos:Int):{done:Bool, read:Int, write:Int} {
        var totalInBefore = deflater.getTotalIn();
        var totalOutBefore = deflater.getTotalOut();
        
        var availableInput = src.length - srcPos;
        var inputGiven = false;
        
        if (availableInput > 0 && deflater.needsInput() && !finish) {
            deflater.setInput(src.getData(), srcPos, availableInput);
            inputGiven = true;
        }
        
        if (finish) {
            deflater.finish();
        }

        var totalWritten = 0;
        var remainingDstSpace = dst.length - dstPos;
        
        if (finish) {
            while (remainingDstSpace > totalWritten && !deflater.finished()) {
                var written = deflater.deflate(dst.getData(), dstPos + totalWritten, remainingDstSpace - totalWritten);
                if (written == 0) break;
                totalWritten += written;
            }
        } else {
            totalWritten = deflater.deflate(dst.getData(), dstPos, remainingDstSpace);
        }
        
        var totalInAfter = deflater.getTotalIn();
        var totalOutAfter = deflater.getTotalOut();
        
        var bytesRead = totalInAfter - totalInBefore;
        var bytesWritten = totalOutAfter - totalOutBefore;
        
        var isFinished = deflater.finished();
        
        if (finish && bytesRead == 0 && bytesWritten > 0) {
            bytesRead = 1;
        }
        
        if (finish && isFinished) {
            finish = false;
        }

        return {
            done: isFinished, 
            read: bytesRead, 
            write: bytesWritten
        };
    }

    public function setFlushMode(f:FlushMode) {
        this.mode = switch (f) {
            case NO:
                Deflater.NO_FLUSH;
            case SYNC:
                Deflater.SYNC_FLUSH;
            case FULL:
                Deflater.FULL_FLUSH;
            case FINISH:
                this.finish = true;
                Deflater.FULL_FLUSH;
            case BLOCK:
                throw new haxe.exceptions.NotImplementedException();
        }
    }

    public function close() {
        deflater.end();
    }

    public static function run(s:haxe.io.Bytes, level:Int):haxe.io.Bytes {
        var deflater = new java.util.zip.Deflater(level);
        deflater.setInput(s.getData());
        var outputStream = new java.io.ByteArrayOutputStream(s.length);
        deflater.finish();
        var buffer = haxe.io.Bytes.alloc(1024).getData();
        while (!deflater.finished()) {
            var count = deflater.deflate(buffer);
            outputStream.write(buffer, 0, count);
        }
        outputStream.close();
        return haxe.io.Bytes.ofData(outputStream.toByteArray());
    }
}
#else
typedef Compress = haxe.zip.Compress;
#end