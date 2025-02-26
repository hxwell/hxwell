package hx.well.tools;
import haxe.macro.Expr.Field;
using hx.well.tools.ArrayFilterTools;
using Lambda;

class FieldTools {
    public static function getField(fields:Array<Field>, fieldName:String):Null<Field> {
        return fields.find(field -> field.name == fieldName);
    }

    public static function getFieldOrFail(fields:Array<Field>, fieldName:String):Field {
        var field:Null<Field> = getField(fields, fieldName);
        if(field == null)
            throw '${fieldName} field not found';

        return field;
    }
}