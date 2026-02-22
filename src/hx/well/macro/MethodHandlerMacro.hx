package hx.well.macro;

import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Context;
import haxe.macro.Expr.Field;

/**
 * Automatically identify methods in the MethodHandler class and map them to HTTP methods
 */
class MethodHandlerMacro {
	macro public static function build():Array<Field> {
		var fileds = Context.getBuildFields();
		var __methods:Map<String, String> = [];
		for (filed in fileds) {
			switch filed.kind {
				case FVar(t, e):
				case FFun(f):
					if (!filed.access.contains(APublic))
						continue;
					if (f.args.length == 1) {
						var type = ComplexTypeTools.toString(f.args[0].type);
						var retType = ComplexTypeTools.toString(f.ret);
						if (type != "Request" || retType != "AbstractResponse") {
							continue;
						}
					} else {
						continue;
					}
					var get = false;
					var post = false;
					for (meta in filed.meta) {
						if (meta.name == ":get") {
							get = true;
						} else if (meta.name == ":post") {
							post = true;
						}
					}
					if (!get || !post) {
						if (get) {
							__methods.set(filed.name, "GET");
						} else if (post) {
							__methods.set(filed.name, "POST");
						} else {
							__methods.set(filed.name, "ANY");
						}
					} else {
						__methods.set(filed.name, "ANY");
					}
				case FProp(get, set, t, e):
			}
		}
		fileds.push({
			name: "__internal",
			access: [AOverride],
			kind: FFun({
				args: [],
				expr: macro {
					super.__internal();
					methods = $v{__methods};
				},
				ret: macro :Void
			}),
			pos: Context.currentPos()
		});
		return fileds;
	}
}
