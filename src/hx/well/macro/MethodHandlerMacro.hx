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
	private static var httpMethodMeta:Map<String, String> = [
		":get" => "GET",
		":post" => "POST",
		":put" => "PUT",
		":delete" => "DELETE",
		":patch" => "PATCH",
		":head" => "HEAD",
		":options" => "OPTIONS",
		":any" => "ANY"
	];

	macro public static function build():Array<Field> {
		var fileds = Context.getBuildFields();
		var __methods:Map<String, {
			methods:Array<String>,
			validators:Map<String, Array<hx.well.validator.ValidatorRule>>
		}> = [];
		for (filed in fileds) {
			switch filed.kind {
				case FVar(t, e):
				case FFun(f):
					if (!filed.access.contains(APublic))
						continue;
					if (f.args.length == 1) {
						try {
							var type = ComplexTypeTools.toString(f.args[0].type).split(".").pop();
							var retType = ComplexTypeTools.toString(f.ret).split(".").pop();
							if (type != "Request" || retType != "AbstractResponse") {
								continue;
							}
						} catch (e:Dynamic) {
							continue;
						}
					} else {
						continue;
					}
					var httpMethods:Array<String> = [];
					var validators:Map<String, Array<hx.well.validator.ValidatorRule>> = [];
					for (meta in filed.meta) {
						if (httpMethodMeta.exists(meta.name)) {
							var httpMethod = httpMethodMeta.get(meta.name);
							if (!httpMethods.contains(httpMethod))
								httpMethods.push(httpMethod);
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
					if (httpMethods.length == 0) {
						Context.warning('Method "${filed.name}" is exposed for every HTTP method. Add @:get/@:post/... (or @:any to silence this warning) to make the exposure explicit.', filed.pos);
						httpMethods = ["ANY"];
					} else if (httpMethods.contains("ANY")) {
						httpMethods = ["ANY"];
					}
					__methods.set(filed.name, {
						methods: httpMethods,
						validators: validators
					});
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
