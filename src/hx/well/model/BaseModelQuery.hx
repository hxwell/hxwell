package hx.well.model;

import haxe.ds.StringMap;
import hx.well.database.query.QueryBuilder;
import hx.well.http.Response;
import sys.db.ResultSet;

// TODO: Add support for relationships (hasOne, hasMany, belongsTo, belongsToMany)
class BaseModelQuery<T:BaseModel<T>> {
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

    public function insert(data:StringMap<Dynamic>):Int {
        var pk:Dynamic = parent.primaryKeyFactory();
        if(pk != null && !data.exists(getPrimary())) {
            data.set(getPrimary(), pk);
        }
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

    public function getResultSetResponse(?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):Response {
        return new QueryBuilder(parent).getResultSetResponse(resultSetReplacer, statusCode);
    }

    public function create(data:StringMap<Dynamic>):T {
        var id:Int = insert(data);
        var primaryKey:String = getPrimary();
        return data.exists(primaryKey) ? find(data.get(primaryKey)) : find(id);
    }
}