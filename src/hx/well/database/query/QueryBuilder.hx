package hx.well.database.query;
import hx.well.model.BaseModel;
import hx.well.database.query.QueryBuilder;
import sys.db.ResultSet;
import hx.well.http.ResultSetResponse;
import hx.well.facades.DB;

@:allow(hx.well.database.query.SelectQueryBuilder)
@:allow(hx.well.database.query.DeleteQueryBuilder)
@:allow(hx.well.database.query.UpdateQueryBuilder)
@:allow(hx.well.database.query.InsertQueryBuilder)
@:allow(hx.well.model.BaseModel)
@:access(hx.well.HxWell)
class QueryBuilder<T> {
    private var model:BaseModel<T>;
    private var columns:Array<String> = ["*"];
    private var conditions:Array<String> = [];
    private var joins:Array<String> = [];
    private var values:Array<Dynamic> = [];
    private var orderByClause:String = "";
    private var limitValue:Int = -1;
    private var queryUnsafe:Bool = false;
    private var db:DB;

    public function new(model:BaseModel<T>) {
        this.model = model;

        db = new DB().setConnection(this.model.__connection);
    }

    public function select(columns:Array<String>):QueryBuilder<T> {
        this.columns = columns;
        return this;
    }

    public function where(column:String, op:String, value:Dynamic):QueryBuilder<T> {
        conditions.push('$column $op ?');
        values.push(value);
        return this;
    }

    public function whereIn(column:String, values:Array<Dynamic>):QueryBuilder<T> {
        if (values.length == 0) {
            conditions.push("1=0");
            return this;
        }

        var placeholders = [for (_ in 0...values.length) '?'].join(',');
        conditions.push('$column IN ($placeholders)');
        for (v in values) {
            this.values.push(v);
        }
        return this;
    }

    public function whereNotIn(column:String, values:Array<Dynamic>):QueryBuilder<T> {
        if (values.length == 0) {
            return this;
        }

        var placeholders = [for (_ in 0...values.length) '?'].join(',');
        conditions.push('$column NOT IN ($placeholders)');
        for (v in values) {
            this.values.push(v);
        }
        return this;
    }

    public function innerJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return join("INNER", table, column1, op, column2);
    }

    public function leftJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return join("LEFT", table, column1, op, column2);
    }

    public function rightJoin(table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        return join("RIGHT", table, column1, op, column2);
    }

    public function join(type:String, table:String, column1:String, op:String, column2:String):QueryBuilder<T> {
        joins.push('$type JOIN $table ON $column1 $op $column2');
        return this;
    }

    public function orderBy(column:String, direction:String = "ASC"):QueryBuilder<T> {
        this.orderByClause = 'ORDER BY $column $direction';
        return this;
    }

    public function limit(limit:Int):QueryBuilder<T> {
        this.limitValue = limit;
        return this;
    }

    public inline function toSelectSql():String {
        return SelectQueryBuilder.toString(this);
    }

    public inline function toUpdateSql(keys:Iterator<String>):String {
        return UpdateQueryBuilder.toString(this, keys);
    }

    public inline function toDeleteSql():String {
        return DeleteQueryBuilder.toString(this);
    }

    public function first():Null<T> {
        return convertResult(db.select(toSelectSql(), ...values)[0]);
    }

    public function get():Array<T> {
        return db.select(toSelectSql(), ...values).map(element -> convertResult(element));
    }

    public function update(data:Map<String, Dynamic>):Void {
        var values:Array<Dynamic> = [for(value in data) value].concat(this.values);
        db.update(toUpdateSql(data.keys()), ...values);
    }

    public function delete():Void {
        db.delete(toDeleteSql(), ...values);
    }

    public function getResultSet():ResultSet {
        return db.query(toSelectSql(), ...values);
    }

    private function insert(data:Map<String, Dynamic>):Int {
        return db.insert(InsertQueryBuilder.toString(this, data.keys()), ...[for(value in data) value]);
    }

    public function unsafe(value:Bool):QueryBuilder<T> {
        this.queryUnsafe = value;
        return this;
    }

    public function getResultSetResponse(?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):ResultSetResponse {
        return new ResultSetResponse(getResultSet(), model.getVisibleDatabaseFields(), resultSetReplacer, statusCode);
    }

    private function convertResult(data:Dynamic):T {
        if(data == null)
            return null;

        var model = Type.createInstance(Type.getClass(model), []);
        var fields = model.getDatabaseFields();
        for(field in fields)
        {
            if(Reflect.hasField(data, field))
                Reflect.setField(model, field, Reflect.field(data, field));
        }
        return cast model;
    }
}