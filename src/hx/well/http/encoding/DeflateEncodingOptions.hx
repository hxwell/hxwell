package hx.well.http.encoding;
class DeflateEncodingOptions implements IEncodingOptions {
    public var level(default, set):Int;
    public function set_level(value:Int):Int {
        if (value < 0 || value > 9) {
            throw new haxe.Exception("Compression level must be between 0 and 9");
        }
        level = value;
        return level;
    }

    public var chunkSize(default, set):Int; // 64 KB
    public function set_chunkSize(value:Int):Int {
        if (value <= 0) {
            throw new haxe.Exception("Chunk size must be greater than 0");
        }
        chunkSize = value;
        return chunkSize;
    }

    public function new(level:Int = 1, chunkSize:Int = 64 * 1024) {
        this.level = level;
        this.chunkSize = chunkSize;
    }
}