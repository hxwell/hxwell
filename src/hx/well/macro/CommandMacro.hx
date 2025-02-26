package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Context;

class CommandMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        trace(Context.getLocalClass().get().name);

         return fields;
    }
}