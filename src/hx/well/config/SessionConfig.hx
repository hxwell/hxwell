package hx.well.config;
import hx.well.facades.Environment.Environment.env;
using Std;

class SessionConfig implements IConfig {
    public function new() {}

    public var path:String = env("SESSION_PATH", "session");
    public var lifetime:Int = env("SESSION_LIFETIME", "360").parseInt();
}
