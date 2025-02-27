package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.io.Bytes;
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
            #if jvm
            createWriteBytes(fields);
            #end
            patchFunction(fields, "writeByte");
            patchFunction(fields, "writeBytes");
        }

        return fields;
    }

    #if jvm
    private static function createWriteBytes(fields:Array<Field>):Void {
        var writeByteField = fields.filter(field -> field.name == "writeBytes")[0];
        if(writeByteField != null)
            return;

        var func:Function = {
            args: [
                { name: "s", type: macro : Bytes },
                { name: "pos", type: macro : Int },
                { name: "len", type: macro : Int }
            ],
            ret: macro : Int,
            expr: macro {
                if (pos < 0 || len < 0 || pos + len > s.length)
                    throw haxe.io.Error.OutsideBounds;
                try {
                    stream.write(s.getData(), pos, len);
                } catch (e:EOFException) {

                    throw new Eof();
                } catch (e:IOException) {
                    throw haxe.io.Error.Custom(e);
                }
                return len;
            }
        };

        fields.push({
            name: "writeBytes",
            access: [Access.APublic, Access.AOverride],
            kind: FieldType.FFun(func),
            pos: Context.currentPos()
        });
    }
    #end

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
