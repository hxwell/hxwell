package hx.well.facades;
import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Type;
#end

class Config {
    public static macro function get(key:String):Expr {
        return resolve(key);
    }

    public static macro function set(key:String, value:Expr):Expr {
        var access:Expr = resolve(key);
        return macro $access = $value;
    }

    public static macro function config(key:String):Expr {
        return resolve(key);
    }

    #if macro
    private static function resolve(key:String):Expr {
        var keys:Array<String> = key.split(".");
        var fieldName:String = keys[0] + "config";

        var identifier = ~/^[a-zA-Z_][a-zA-Z0-9_]*$/;
        for (part in [fieldName].concat(keys.slice(1))) {
            if (!identifier.match(part))
                Context.error('Invalid config key "${key}"', Context.currentPos());
        }

        validateConfigExists(keys[0], fieldName);

        var path:Array<String> = ["hx", "well", "config", "ConfigData", fieldName].concat(keys.slice(1));
        return macro $p{path};
    }

    private static function validateConfigExists(configName:String, fieldName:String):Void {
        var available:Array<String> = null;

        try {
            switch (Context.getType("hx.well.config.ConfigData")) {
                case TInst(classRef, _):
                    var statics = classRef.get().statics.get();
                    if (Lambda.exists(statics, field -> field.name == fieldName))
                        return;

                    available = [
                        for (field in statics)
                            if (field.name != "init" && StringTools.endsWith(field.name, "config"))
                                field.name.substr(0, field.name.length - "config".length)
                    ];
                case _:
                    return;
            }
        } catch (e:Dynamic) {
            return;
        }

        Context.error('Unknown config "${configName}". Define a class whose lowercased name is "${fieldName}" (e.g. "${configName.charAt(0).toUpperCase() + configName.substr(1)}Config") implementing hx.well.config.IConfig in the hx.well.config package. Available configs: ${available.join(", ")}', Context.currentPos());
    }
    #end
}