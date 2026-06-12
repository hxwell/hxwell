package hx.well.config;

import haxe.ds.StringMap;
import hx.well.auth.IAuthenticatable;

class SessionConfig implements IConfig {
    public function new() {}

    public var path:String = "session";
    public var lifetime:Int = 360;
    public var guards:StringMap<Class<IAuthenticatable>> = new StringMap();
}
