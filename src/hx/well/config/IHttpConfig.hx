package hx.well.config;
using Std;

interface IHttpConfig extends IConfig {
    public var max_path_length:Int;
    public var max_buffer:Int;
    public var max_content_length:Int;

    public var public_path:String;
}
