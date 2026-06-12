package hx.well.config;

class HttpConfig implements IConfig {
    public function new() {}

    public var max_path_length:Int = 1024;
    public var max_buffer:Int = 8192;
    public var max_content_length:Int = 1048576;
    public var public_path:String = "public";
    public var cache_path:String = "cache";
}
