package hx.well.database.schema;

import haxe.Exception;

class SqliteSchemaGrammar extends SchemaGrammar {
    private override function typeSql(column:ColumnDefinition):String {
        if (isIncrementsColumn(column))
            return "INTEGER PRIMARY KEY AUTOINCREMENT";

        return switch (column.type) {
            case TIncrements | TBigIncrements: "INTEGER PRIMARY KEY AUTOINCREMENT";
            case TInteger | TTinyInteger | TSmallInteger | TMediumInteger | TBigInteger | TYear: "INTEGER";
            case TString | TChar | TUuid: "VARCHAR";
            case TText | TMediumText | TLongText | TJson: "TEXT";
            case TBoolean: "TINYINT(1)";
            case TFloat: "FLOAT";
            case TDouble: "DOUBLE";
            case TDecimal: "NUMERIC";
            case TDate: "DATE";
            case TDateTime | TTimestamp: "DATETIME";
            case TTime: "TIME";
            case TBinary: "BLOB";
            case TEnum: 'VARCHAR CHECK (${quote(column.name)} IN (${column.allowed.map(value -> "'" + escapeString(value) + "'").join(", ")}))';
            case TSet: throw new Exception("SQLite does not support set columns.");
            case TGeometry: "GEOMETRY";
        }
    }

    private override function tableOptionsSql(blueprint:Blueprint):String {
        return "";
    }

    private override function compileChangeColumn(table:String, column:ColumnDefinition):String {
        throw new Exception("SQLite column changes are applied through SchemaBuilder table recreation.");
    }

    private override function compileUnique(table:String, columns:Array<String>, name:String):String {
        return 'CREATE UNIQUE INDEX ${quote(name)} ON ${quote(table)} (${quoteList(columns)})';
    }

    private override function compileIndex(table:String, columns:Array<String>, name:String):String {
        return 'CREATE INDEX ${quote(name)} ON ${quote(table)} (${quoteList(columns)})';
    }

    private override function compileFullText(table:String, columns:Array<String>, name:String):String {
        throw new Exception("SQLite does not support fulltext indexes.");
    }

    private override function compileSpatialIndex(table:String, columns:Array<String>, name:String):String {
        throw new Exception("SQLite does not support spatial indexes.");
    }

    private override function compileRenameIndex(table:String, from:String, to:String):String {
        throw new Exception("SQLite index renames are applied through SchemaBuilder recreation.");
    }

    private override function compileAddPrimary(table:String, columns:Array<String>, name:Null<String>):String {
        throw new Exception("SQLite does not support adding primary keys to existing tables.");
    }

    private override function compileAddForeign(table:String, foreign:ForeignKeyDefinition):String {
        throw new Exception("SQLite does not support adding foreign keys to existing tables.");
    }

    private override function compileDropIndex(table:String, name:String):String {
        return 'DROP INDEX ${quote(name)}';
    }

    private override function compileDropPrimary(table:String):String {
        throw new Exception("SQLite does not support dropping primary keys.");
    }

    private override function compileDropForeign(table:String, name:String):String {
        throw new Exception("SQLite does not support dropping foreign keys.");
    }

    public override function compileRename(from:String, to:String):String {
        return 'ALTER TABLE ${quote(from)} RENAME TO ${quote(to)}';
    }

    public override function compileTableExists(table:String):String {
        return 'SELECT name FROM sqlite_master WHERE type = \'table\' AND name = \'${escapeString(table)}\'';
    }

    public override function compileColumnListing(table:String):String {
        return 'PRAGMA table_xinfo(${quote(table)})';
    }

    public override function compileTableListing():String {
        return "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'";
    }

    public override function compileIndexListing(table:String):String {
        return 'PRAGMA index_list(${quote(table)})';
    }

    public override function compileEnableForeignKeyConstraints():String {
        return "PRAGMA foreign_keys = ON";
    }

    public override function compileDisableForeignKeyConstraints():String {
        return "PRAGMA foreign_keys = OFF";
    }
}
