package hx.well.http;
import sys.io.FileInput;
import haxe.io.Input;
import haxe.Int64;
import sys.db.ResultSet;
import haxe.Template;
import hx.well.exception.AbortException;
import haxe.Exception;
import hx.well.template.TemplateData;
class ResponseBuilder {
    public static function asRedirect(url:String, statusCode:Null<Int> = null):Response {
        statusCode = statusCode == null ? 302 : statusCode;

        return new Response(statusCode)
            .header("Location", url);
    }

    public static inline function asStatic():Response {
        return ResponseStatic.get();
    }

    public static inline function asString(body:String, statusCode:Null<Int> = null):StringResponse {
        return new StringResponse(body, statusCode);
    }

    public static inline function asJson(data:Dynamic, statusCode:Null<Int> = null):JsonResponse {
        return new JsonResponse(data, statusCode);
    }

    public static inline function asFileInput(input:FileInput, statusCode:Null<Int> = null):FileInputResponse {
        return new FileInputResponse(input, statusCode);
    }

    public static inline function asInput(input:Input, size:Null<Int64>, statusCode:Null<Int> = null):InputResponse {
        return new InputResponse(input, size, statusCode);
    }

    public static inline function asResultSet(resultSet:ResultSet, ?visibleFields:Array<String>, ?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):ResultSetResponse {
        return new ResultSetResponse(resultSet, visibleFields, resultSetReplacer, statusCode);
    }

    public static inline function asAsync():AsyncResponse {
        return new AsyncResponse();
    }

    public static function asTemplate(name:String, ?context:Dynamic, ?macros:Dynamic, statusCode:Null<Int> = null):StringResponse {
        var template:Template = TemplateData.data.get(name);
        if(template == null)
            throw new Exception('${name} template not found.');

        var body = template.execute(context, macros);
        return asString(body, statusCode);
    }

    public static inline function abort(code:Int, ?status:String):Void
    {
        throw new AbortException(code, status);
    }
}
