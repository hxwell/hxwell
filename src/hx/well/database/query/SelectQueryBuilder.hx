package hx.well.database.query;
import hx.well.model.User;
import hx.well.model.BaseModel;
import sys.db.Connection;
import hx.well.database.Connection as HxWellConnection;
import hx.well.database.query.SelectQueryBuilder;
import sys.db.ResultSet;
import hx.well.http.ResultSetResponse;
import hx.well.facades.DB;

@:access(hx.well.HxWell)
class SelectQueryBuilder<T> {
    private var model:BaseModel<T>;
    private var columns:Array<String> = ["*"];
    private var conditions:Array<String> = [];
    private var joins:Array<String> = [];
    private var values:Array<Dynamic> = [];
    private var orderByClause:String = "";
    private var limitValue:Int = -1;
    private var db:DB;

    public function new(model:BaseModel<T>) {
        this.model = model;

        db = new DB().setConnection(this.model.__connection);
    }

    public function select(columns:Array<String>):SelectQueryBuilder<T> {
        this.columns = columns;
        return this;
    }

    public function where(column:String, op:String, value:Dynamic):SelectQueryBuilder<T> {
        conditions.push('$column $op ?');
        values.push(value);
        return this;
    }

    public function innerJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return join("INNER", table, column1, op, column2);
    }

    public function leftJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return join("LEFT", table, column1, op, column2);
    }

    public function rightJoin(table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        return join("RIGHT", table, column1, op, column2);
    }

    public function join(type:String, table:String, column1:String, op:String, column2:String):SelectQueryBuilder<T> {
        joins.push('$type JOIN $table ON $column1 $op $column2');
        return this;
    }

    public function orderBy(column:String, direction:String = "ASC"):SelectQueryBuilder<T> {
        this.orderByClause = 'ORDER BY $column $direction';
        return this;
    }

    public function limit(limit:Int):SelectQueryBuilder<T> {
        this.limitValue = limit;
        return this;
    }

    public function toSql():String {
        var sql = 'SELECT ${columns.join(", ")} FROM ${this.model.getTable()}';
        if (joins.length > 0) sql += ' ' + joins.join(" ");
        if (conditions.length > 0) sql += ' WHERE ' + conditions.join(" AND ");
        if (orderByClause != "") sql += ' $orderByClause';
        if (limitValue > 0) sql += ' LIMIT $limitValue';
        return sql;
    }

    public function first():Null<T> {
        return convertResult(db.select(toSql(), ...values)[0]);
    }

    public function get():Array<T> {
        return db.select(toSql(), ...values).map(element -> convertResult(element));
    }

    public function getResultSet():ResultSet {
        return db.query(toSql(), ...values);
    }

    public function getResultSetResponse(?resultSetReplacer:Dynamic->Void, statusCode:Null<Int> = null):ResultSetResponse {
        return new ResultSetResponse(getResultSet(), model.getVisibleDatabaseFields(), resultSetReplacer, statusCode);
    }

    private function convertResult(data:Dynamic):T {
        if(data == null)
            return null;

        //var model = Type.createInstance(T, []);
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