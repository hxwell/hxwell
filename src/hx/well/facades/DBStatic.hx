package hx.well.facades;
import sys.db.ResultSet;
class DBStatic {
    public static function connection(key:String):DB {
        return new DB().setConnection(key);
    }

    public static function select(rawQuery:String, ...parameters:Dynamic):Array<Dynamic> {
        return new DB().select(rawQuery, ...parameters);
    }

    public static function update(rawQuery:String, ...parameters:Dynamic) {
        return new DB().update(rawQuery, ...parameters);
    }

    public static function insert(rawQuery:String, ...parameters:Dynamic):Int {
        return new DB().insert(rawQuery, ...parameters);
    }

    public static function query(rawQuery:String, ...parameters:Dynamic):ResultSet {
        return new DB().query(rawQuery, ...parameters);
    }

    public static function transaction(callback:()->Void):Void {
       return new DB().transaction(callback);
    }
}
