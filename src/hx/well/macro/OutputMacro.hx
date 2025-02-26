package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Expr;
import haxe.macro.Context;
class OutputMacro {
    public static function build():Array<Field> {
        var localClass = Context.getLocalClass();
        var localClassName = localClass.get().name;
        //trace(localClassName);
        var fields = Context.getBuildFields();

        if(localClassName == "Output")
        {
            fields.push({
                name: "isWrited",
                doc: null,
                meta: [],
                access: [APublic],
                kind: FVar(macro:Bool, macro false),
                pos: Context.currentPos()
            });
            patchFunction(fields, "writeByte");
        }else if(localClassName == "NativeOutput")
        {
            patchFunction(fields, "writeByte");
            patchFunction(fields, "writeBytes");
        }

        return fields;
    }

    private static function patchFunction(fields:Array<Field>, name:String):Void
    {
        var writeByteField = fields.filter(field -> field.name == name)[0];
        if(writeByteField == null)
            return;

        var exprs = [];

        switch (writeByteField.kind)
        {
            case FFun(f):
                exprs.push(macro {
                    this.isWrited = true;
                });
                exprs.push(f.expr);
                f.expr = macro $b{exprs};
                writeByteField.kind = FFun(f);
            default:
        }
    }
}
