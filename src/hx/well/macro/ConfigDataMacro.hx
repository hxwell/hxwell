
package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.ds.StringMap;

class ConfigDataMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        var exprs:Array<Expr> = [];

        for(clazz in ConfigAutoBuildMacro.classes) {
            var fullClass:String = '${clazz.pack.join(".")}.${clazz.name}';
            var formattedName:String = clazz.name.toLowerCase();
            trace(formattedName);

            // Create the complex type for the field
            var complexType = TPath({
                pack: clazz.pack,
                name: clazz.name
            });

            var newInstanceExpr = {
                expr: ENew({
                    pack: clazz.pack,
                    name: clazz.name
                }, []),
                pos: Context.currentPos()
            };

            exprs.push(macro $i{formattedName} = $newInstanceExpr);

            fields.push({
                name: formattedName,
                kind: FVar(complexType, null), // Fixed: Removed nested FVar and incorrect macro syntax
                pos: Context.currentPos(),
                access: [APublic, AStatic] // Added public access
            });
        }

        fields.push({
            name: "init",
            kind: FFun({
                args: [],
                expr: macro $b{exprs}
            }),
            pos: Context.currentPos(),
            access: [APublic, AStatic] // Added public access
        });
        return fields;
    }
}