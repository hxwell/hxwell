package hx.well.model;
import hx.well.database.query.SelectQueryBuilder;
import hx.well.http.Response;
import hx.well.http.JsonResponse;
import hx.well.http.IResponseInstance;
import sys.db.ResultSet;

class BaseModel<T> implements IResponseInstance {
    public var __connection:String = "default";
    public var __table:String;
    public var __primary:String;

    public function new() {

    }

    public function find(id:Dynamic):Null<T> {
        return where(__primary, "=", id).first();
    }

    public function select(columns:Array<String>):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).select(columns);
    }

    public function where(column:String, op:String, value:Dynamic):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).where(column, op, value);
    }

    public function innerJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).innerJoin(table, column1, op, column2);
    }

    public function leftJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).leftJoin(table, column1, op, column2);
    }

    public function rightJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).rightJoin(table, column1, op, column2);
    }

    public function join(type:String, table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).join(type, table, column1, op, column2);
    }

    public function orderBy(column:String, direction:String = "ASC"):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).orderBy(column, direction);
    }

    public function limit(limit:Int):SelectQueryBuilder<T> {
        return new SelectQueryBuilder(this).limit(limit);
    }

    public function get():Array<T> {
        return new SelectQueryBuilder(this).get();
    }

    public function getResultSet():ResultSet {
        return new SelectQueryBuilder(this).getResultSet();
    }

    public function getResultSetResponse(?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):Response {
        return new SelectQueryBuilder(this).getResultSetResponse(resultSetReplacer, statusCode);
    }

    public inline function getTable():String {
        return __table;
    }

    public function setTable(value:String):Void {
        __table = value;
    }

    public function setConnection(value:String):Void {
        __connection = value;
    }

    public function getPrimary():String {
        return __primary;
    }

    public function setPrimary(value:String):Void {
        __primary = value;
    }

    public function getDatabaseFields():Array<String> {
        return [];
    }

    public function getVisibleDatabaseFields():Array<String> {
        return [];
    }

    public function getResponse():Response {
        var data:Dynamic = {};

        for(field in getVisibleDatabaseFields())
        {
            var fieldValue:Dynamic = Reflect.getProperty(this, field);
            Reflect.setProperty(data, field, fieldValue);
        }

        return new JsonResponse(data);
    }
}
