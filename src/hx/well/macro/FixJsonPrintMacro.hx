package hx.well.macro;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import hx.well.tools.FieldTools;
class FixJsonPrintMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        var writeField = FieldTools.getField(fields, "write");
        switch (writeField.kind) {
            case FFun(f):
                f.expr = macro {
                    if (replacer != null)
                        v = replacer(k, v);
                    switch (Type.typeof(v)) {
                        case TUnknown:
                            #if hl
				if(haxe.Int64.isInt64(v))
					add(haxe.Int64.toStr(v));
				else
				#end
                            add('"???"');
                        case TObject:
                            objString(v);
                        case TInt:
                            add(#if (jvm || hl) Std.string(v) #else v #end);
                        case TFloat:
                            add(Math.isFinite(v) ? Std.string(v) : 'null');
                        case TFunction:
                            add('"<fun>"');
                        case TClass(c):
                            if (c == String)
                                quote(v);
                            else if (c == Array) {
                                var v:Array<Dynamic> = v;
                                addChar('['.code);

                                var len = v.length;
                                var last = len - 1;
                                for (i in 0...len) {
                                    if (i > 0)
                                        addChar(','.code)
                                    else
                                        nind++;
                                    newl();
                                    ipad();
                                    write(i, v[i]);
                                    if (i == last) {
                                        nind--;
                                        newl();
                                        ipad();
                                    }
                                }
                                addChar(']'.code);
                            } else if (c == haxe.ds.StringMap) {
                                var v:haxe.ds.StringMap<Dynamic> = v;
                                var o = {};
                                for (k in v.keys())
                                    Reflect.setField(o, k, v.get(k));
                                objString(o);
                            } else if (c == Date) {
                                var v:Date = v;
                                quote(v.toString());
                            } else if(haxe.Int64.isInt64(v))
                                add(haxe.Int64.toStr(v));
                            else
                                classString(v);
                        case TEnum(_):
                            var i = Type.enumIndex(v);
                            add(Std.string(i));
                        case TBool:
                            add(#if (php || jvm || hl) (v ? 'true' : 'false') #else v #end);
                        case TNull:
                            add('null');
                    }
                };
            default:
        }

        return fields;
    }
}
