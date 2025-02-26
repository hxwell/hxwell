package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import hx.well.tools.FieldTools;
import haxe.macro.TypeTools;
class CacheMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cacheType = Context.getType("hx.well.facades.Cache");
        var field = switch (cacheType) {
            case TInst(t, params):
                TypeTools.findField(t.get(), "cacheStores", true);
            default:
                null;
        }

        var expr = Context.getTypedExpr(field.expr());
        var exprs = [];
        exprs.push(macro $v{"test"});
        expr = macro $a{exprs};

        return fields;
    }
}
