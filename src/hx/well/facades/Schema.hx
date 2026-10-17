package hx.well.facades;

import hx.well.database.schema.Blueprint;
import hx.well.database.schema.SchemaBuilder;

class Schema {
    public static function connection(key:String):SchemaBuilder {
        return new SchemaBuilder(key);
    }

    public static function defaultStringLength(length:Int):Void {
        SchemaBuilder.defaultStringLength = length;
    }

    public static function create(table:String, callback:Blueprint->Void):Void {
        new SchemaBuilder().create(table, callback);
    }

    public static function table(table:String, callback:Blueprint->Void):Void {
        new SchemaBuilder().table(table, callback);
    }

    public static function drop(table:String):Void {
        new SchemaBuilder().drop(table);
    }

    public static function dropIfExists(table:String):Void {
        new SchemaBuilder().dropIfExists(table);
    }

    public static function dropColumns(table:String, columns:Array<String>):Void {
        new SchemaBuilder().dropColumns(table, columns);
    }

    public static function dropAllTables():Void {
        new SchemaBuilder().dropAllTables();
    }

    public static function rename(from:String, to:String):Void {
        new SchemaBuilder().rename(from, to);
    }

    public static function hasTable(table:String):Bool {
        return new SchemaBuilder().hasTable(table);
    }

    public static function hasColumn(table:String, column:String):Bool {
        return new SchemaBuilder().hasColumn(table, column);
    }

    public static function hasColumns(table:String, columns:Array<String>):Bool {
        return new SchemaBuilder().hasColumns(table, columns);
    }

    public static function hasIndex(table:String, index:String):Bool {
        return new SchemaBuilder().hasIndex(table, index);
    }

    public static function getColumnListing(table:String):Array<String> {
        return new SchemaBuilder().getColumnListing(table);
    }

    public static function getIndexListing(table:String):Array<String> {
        return new SchemaBuilder().getIndexListing(table);
    }

    public static function getTableListing():Array<String> {
        return new SchemaBuilder().getTableListing();
    }

    public static function whenTableHasColumn(table:String, column:String, callback:Blueprint->Void):Void {
        new SchemaBuilder().whenTableHasColumn(table, column, callback);
    }

    public static function whenTableDoesntHaveColumn(table:String, column:String, callback:Blueprint->Void):Void {
        new SchemaBuilder().whenTableDoesntHaveColumn(table, column, callback);
    }

    public static function createDatabase(name:String):Void {
        new SchemaBuilder().createDatabase(name);
    }

    public static function dropDatabaseIfExists(name:String):Void {
        new SchemaBuilder().dropDatabaseIfExists(name);
    }

    public static function enableForeignKeyConstraints():Void {
        new SchemaBuilder().enableForeignKeyConstraints();
    }

    public static function disableForeignKeyConstraints():Void {
        new SchemaBuilder().disableForeignKeyConstraints();
    }

    public static function withoutForeignKeyConstraints(callback:()->Void):Void {
        new SchemaBuilder().withoutForeignKeyConstraints(callback);
    }
}
