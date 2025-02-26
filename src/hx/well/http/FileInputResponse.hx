package hx.well.http;
import sys.io.FileInput;
import haxe.Int64;
import sys.io.FileSeek;
class FileInputResponse extends InputResponse {
    public function new(input:FileInput, statusCode:Null<Int> = null) {
        input.seek(0, FileSeek.SeekEnd);
        var size:Int64 = input.tell();
        input.seek(0, FileSeek.SeekBegin);
        super(input, size, statusCode);
    }
}
