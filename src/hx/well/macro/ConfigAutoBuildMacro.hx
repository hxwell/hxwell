package hx.well.macro;
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Type.ClassType;
class ConfigAutoBuildMacro {
    public static var classes:Array<ClassType> = [];

    macro static public function fromInterface():Array<Field> {
        var fields = Context.getBuildFields();

        var localClass = Context.getLocalClass().get();
        if(!localClass.isInterface)
            classes.push(localClass);


        return fields;
    }
}
