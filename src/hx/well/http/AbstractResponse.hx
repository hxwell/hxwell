package hx.well.http;
import sys.io.FileInput;
import Type.ValueType;
import hx.well.model.BaseModel;
import haxe.ds.Vector;
import sys.db.ResultSet;

abstract AbstractResponse(Response) from Response to Response {
    inline function new(value:Dynamic)
    {
        this = convert(value);
    }

    @:from
    static public inline function fromDynamic(value:Dynamic):AbstractResponse
        return new AbstractResponse(value);

    @:to
    public inline function toResponse():Response
        return cast this;

    public static function convert(value:Dynamic):Response {
        if(value is IResponseInstance)
            value = (value : IResponseInstance).getResponse();

        if(value is Array)
        {
            var arr:Array<Dynamic> = cast value;
            for(i in 0...arr.length) {
                var val:Dynamic = arr[i];

                if(val is IResponseInstance)
                    arr[i] = (val : IResponseInstance).getResponse();
            }
        }

        if(value == null)
            value = "";
        if(value is Response)
            return value;
        else if(value is String)
            return new StringResponse(value);
        else if(value is FileInput)
            return new FileInputResponse(value);
        else if(value is ResultSet)
            return new ResultSetResponse(value);
        else if (Type.typeof(value) == ValueType.TInt || Type.typeof(value) == ValueType.TFloat)
            return new StringResponse(value + "");

        return new JsonResponse(value);
    }
}