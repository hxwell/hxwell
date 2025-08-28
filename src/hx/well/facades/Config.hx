package hx.well.facades;
import haxe.macro.Expr;
import haxe.macro.Context;

class Config {
    public static macro function get<T>(key:String):Expr {
        var keys:Array<String> = key.split(".");
        keys[0] = keys[0] + "config";

        return Context.parse('hx.well.config.ConfigData.${keys.join(".")}', Context.currentPos());
    }
}