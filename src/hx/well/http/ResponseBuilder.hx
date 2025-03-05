package hx.well.http;
import sys.io.FileInput;
import haxe.io.Input;
import haxe.Int64;
import sys.db.ResultSet;
import haxe.Template;
class ResponseBuilder {
    public function new() {

    }

    public inline function asString(body:String, statusCode:Null<Int> = null):StringResponse {
        return new StringResponse(body, statusCode);
    }

    public inline function asJson(data:Dynamic, statusCode:Null<Int> = null):JsonResponse {
        return new JsonResponse(data, statusCode);
    }

    public inline function asFileInput(input:FileInput, statusCode:Null<Int> = null):FileInputResponse {
        return new FileInputResponse(input, statusCode);
    }

    public inline function asInput(input:Input, size:Int64, statusCode:Null<Int> = null):InputResponse {
        return new InputResponse(input, size, statusCode);
    }

    public inline function asResultSet(resultSet:ResultSet, ?visibleFields:Array<String>, ?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):ResultSetResponse {
        return new ResultSetResponse(resultSet, visibleFields, resultSetReplacer, statusCode);
    }

    public function asTemplate(template:Template, context:Dynamic, ?macros:Dynamic, statusCode:Null<Int> = null):StringResponse {
        var body = template.execute(context, macros);
        return asString(body, statusCode);
    }
}
