package hx.well.model;
import hx.well.database.query.QueryBuilder;
import hx.well.http.Response;
import hx.well.http.JsonResponse;
import hx.well.http.IResponseInstance;
import sys.db.ResultSet;
import haxe.ds.StringMap;
import hx.well.facades.DBStatic;
import hx.well.database.query.InsertQueryBuilder;

class BaseModel<T> implements IResponseInstance {
    public var __connection:String = "default";
    public var __table:String;
    public var __primary:String;

    public function new() {

    }

    public function find(id:Dynamic):Null<T> {
        return where(__primary, "=", id).first();
    }

    public function insert(data:Map<String, Dynamic>):Int {
        return new QueryBuilder(this).insert(data);
    }

    public function select(columns:Array<String>):QueryBuilder<T> {
        return new QueryBuilder(this).select(columns);
    }

    public overload extern inline function where(column:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(this).where(column, value);
    }

    public overload extern inline function where(column:String, op:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(this).where(column, op, value);
    }

    public overload extern inline function where(data:StringMap<Dynamic>):QueryBuilder<T> {
        return new QueryBuilder(this).where(data);
    }

    public overload extern inline function orWhere(column:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(this).orWhere(column, value);
    }

    public overload extern inline function orWhere(column:String, op:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(this).orWhere(column, op, value);
    }

    public overload extern inline function orWhere(data:StringMap<Dynamic>):QueryBuilder<T> {
        return new QueryBuilder(this).orWhere(data);
    }

    public function innerJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(this).innerJoin(table, column1, op, column2);
    }

    public function leftJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(this).leftJoin(table, column1, op, column2);
    }

    public function rightJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(this).rightJoin(table, column1, op, column2);
    }

    public function join(type:String, table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(this).join(type, table, column1, op, column2);
    }

    public function orderBy(column:String, direction:String = "ASC"):QueryBuilder<T> {
        return new QueryBuilder(this).orderBy(column, direction);
    }

    public function limit(limit:Int):QueryBuilder<T> {
        return new QueryBuilder(this).limit(limit);
    }

    public function get():Array<T> {
        return new QueryBuilder(this).get();
    }

    public function count():Int {
        return new QueryBuilder(this).count();
    }

    public function getResultSet():ResultSet {
        return new QueryBuilder(this).getResultSet();
    }

    public function getResultSetResponse(?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):Response {
        return new QueryBuilder(this).getResultSetResponse(resultSetReplacer, statusCode);
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

    public function create(data:StringMap<Dynamic>):T {
        var query:String = InsertQueryBuilder.toString(new QueryBuilder(this), data.keys());
        var id:Int = DBStatic.insert(query, ...[for(value in data) value]);
        return find(id);
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
