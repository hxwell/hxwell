package hx.well.facades;
import haxe.macro.Expr;
import haxe.macro.Context;

class Config {
    public static macro function get<T>(key:String):Expr {
        var keys:Array<String> = key.split(".");
        keys[0] = keys[0] + "config";

        return Context.parse('hx.well.config.ConfigData.${keys.join(".")}', Context.currentPos());
    }

    public static macro function set<T>(key:String, value:Dynamic):Expr {
        var keys:Array<String> = key.split(".");
        keys[0] = keys[0] + "config";

        var access:Expr = Context.parse('hx.well.config.ConfigData.${keys.join(".")}', Context.currentPos());
        return macro $access = $value;
    }

    public static macro function config<T>(key:String):Expr {
        var keys:Array<String> = key.split(".");
        keys[0] = keys[0] + "config";

        return Context.parse('hx.well.config.ConfigData.${keys.join(".")}', Context.currentPos());
    }
}