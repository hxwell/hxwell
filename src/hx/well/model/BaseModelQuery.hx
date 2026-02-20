package hx.well.model;

import haxe.ds.StringMap;
import hx.well.database.query.InsertQueryBuilder;
import hx.well.database.query.QueryBuilder;
import hx.well.facades.DBStatic;
import hx.well.http.IResponseInstance;
import hx.well.http.JsonResponse;
import hx.well.http.Response;
import hx.well.interfaces.ISerializable;
import sys.db.ResultSet;

// TODO: Add support for relationships (hasOne, hasMany, belongsTo, belongsToMany)
class BaseModelQuery<T:BaseModel<T>> implements IResponseInstance implements ISerializable {
    private var parent:BaseModel<T>;

    public function new(parent:BaseModel<T>) {
        this.parent = parent;
    }

    public inline function getConnection():String {
        return parent.__connection;
    }

    public inline function getTable():String {
        return parent.__table;
    }

    public inline function getPrimary():String {
        return parent.__primary;
    }

    public function find(id:Dynamic):Null<T> {
        return where(getPrimary(), "=", id).first();
    }

    public function insert(data:Map<String, Dynamic>):Int {
        return new QueryBuilder(parent).insert(data);
    }

    public function select(columns:Array<String>):QueryBuilder<T> {
        return new QueryBuilder(parent).select(columns);
    }

    public overload extern inline function where(column:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(parent).where(column, value);
    }

    public overload extern inline function where(column:String, op:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(parent).where(column, op, value);
    }

    public overload extern inline function where(data:StringMap<Dynamic>):QueryBuilder<T> {
        return new QueryBuilder(parent).where(data);
    }

    public overload extern inline function orWhere(column:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(parent).orWhere(column, value);
    }

    public overload extern inline function orWhere(column:String, op:String, value:Dynamic):QueryBuilder<T> {
        return new QueryBuilder(parent).orWhere(column, op, value);
    }

    public overload extern inline function orWhere(data:StringMap<Dynamic>):QueryBuilder<T> {
        return new QueryBuilder(parent).orWhere(data);
    }

    public function innerJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(parent).innerJoin(table, column1, op, column2);
    }

    public function leftJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(parent).leftJoin(table, column1, op, column2);
    }

    public function rightJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(parent).rightJoin(table, column1, op, column2);
    }

    public function join(type:String, table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return new QueryBuilder(parent).join(type, table, column1, op, column2);
    }

    public function orderBy(column:String, direction:String = "ASC"):QueryBuilder<T> {
        return new QueryBuilder(parent).orderBy(column, direction);
    }

    public function limit(limit:Int):QueryBuilder<T> {
        return new QueryBuilder(parent).limit(limit);
    }

    public function get():Array<T> {
        return new QueryBuilder(parent).get();
    }

    public function count():Int {
        return new QueryBuilder(parent).count();
    }

    public function getResultSet():ResultSet {
        return new QueryBuilder(parent).getResultSet();
    }

    public function getResultSetResponse(?resultSetReplacer:Dynamic -> Void, statusCode:Null<Int> = null):Response {
        return new QueryBuilder(parent).getResultSetResponse(resultSetReplacer, statusCode);
    }

    public function getDatabaseFields():Array<String> {
        return [];
    }

    public function getVisibleDatabaseFields():Array<String> {
        return [];
    }

    public function create(data:StringMap<Dynamic>):T {
        var query:String = InsertQueryBuilder.toString(new QueryBuilder(parent), data.keys());
        var id:Int = DBStatic.insert(query, ...[for (value in data) value]);
        return find(id);
    }

    /**
	 * Convert this model to a plain object containing only visible fields.
	 * Useful for serialization, API responses, and data transfer.
	 * @return Dynamic object with visible fields only
	 */
    public function toObject():Dynamic {
        var data:Dynamic = {};

        for (field in getVisibleDatabaseFields()) {
            var fieldValue:Dynamic = Reflect.getProperty(this, field);
            Reflect.setProperty(data, field, fieldValue);
        }

        return data;
    }

    /**
	 * Get a JSON response containing only visible fields.
	 * @return JsonResponse with visible model data
	 */
    public function getResponse():Response {
        return new JsonResponse(toObject());
    }
}
