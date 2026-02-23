package hx.well.macro;

import hx.well.validator.ValidatorRule;
import haxe.macro.Expr;
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
		var __methods:Map<String, {
			method:String,
			validators:Map<String, Array<hx.well.validator.ValidatorRule>>
		}> = [];
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
					var validators:Map<String, Array<hx.well.validator.ValidatorRule>> = [];
					for (meta in filed.meta) {
						if (meta.name == ":get") {
							get = true;
						} else if (meta.name == ":post") {
							post = true;
						} else if (meta.name == ":validator") {
							var key:String = ExprTools.getValue(meta.params[0]);
							validators[key] = [];
							switch meta.params[1].expr {
								case EArrayDecl(values):
									for (arg in values) {
										switch arg.expr {
											case EField(e, field, kind):
												var rule:hx.well.validator.ValidatorRule = Reflect.getProperty(ValidatorRule, field);
												if (rule == null) {
													throw "invalid validator rule";
												} else {
													validators[key].push(rule);
												}
											case ECall(e, params):
												var callMethod:String = ExprTools.toString(e).split(".")[1];
												var validatorMethod = Reflect.getProperty(ValidatorRule, callMethod);
												if (validatorMethod == null) {
													throw "invalid validator rule";
												} else {
													validators[key].push(Reflect.callMethod(ValidatorRule, validatorMethod,
														params.map((param) -> ExprTools.getValue(param))));
												}
											default:
												throw "invalid validator arguments";
										}
									}
								default:
									throw "invalid validator";
							}
							// var value:hx.well.validator.ValidatorRule = ExprTools.getValue(meta.params[1]);
						}
					}
					if (!get || !post) {
						if (get) {
							__methods.set(filed.name, {
								method: "GET",
								validators: validators
							});
						} else if (post) {
							__methods.set(filed.name, {
								method: "POST",
								validators: validators
							});
						} else {
							__methods.set(filed.name, {
								method: "ANY",
								validators: validators
							});
						}
					} else {
						__methods.set(filed.name, {
							method: "ANY",
							validators: []
						});
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
