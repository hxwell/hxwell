package hx.well.http;
import haxe.io.Input;
import sys.db.ResultSet;
import hx.well.io.ResultSetInput;
class ResultSetResponse extends InputResponse {
    public function new(resultSet:ResultSet, ?visibleFields:Array<String>, ?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null) {
        super(new ResultSetInput(resultSet, visibleFields, resultSetReplacer), null, statusCode);
        header("Content-Type", "application/json");
    }
}