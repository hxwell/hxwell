package hx.well.database.schema;

using StringTools;

class MysqlSchemaGrammar extends SchemaGrammar {
    private override function typeSql(column:ColumnDefinition):String {
        var sql = switch (column.type) {
            case TIncrements: "INT UNSIGNED";
            case TBigIncrements: "BIGINT UNSIGNED";
            case TInteger: "INT";
            case TTinyInteger: "TINYINT";
            case TSmallInteger: "SMALLINT";
            case TMediumInteger: "MEDIUMINT";
            case TBigInteger: "BIGINT";
            case TString: 'VARCHAR(${column.length})';
            case TChar: 'CHAR(${column.length})';
            case TText: "TEXT";
            case TMediumText: "MEDIUMTEXT";
            case TLongText: "LONGTEXT";
            case TBoolean: "TINYINT(1)";
            case TFloat: 'FLOAT(${column.precision ?? 53})';
            case TDouble: "DOUBLE";
            case TDecimal: 'DECIMAL(${column.total}, ${column.places})';
            case TDate: "DATE";
            case TDateTime: "DATETIME";
            case TTime: "TIME";
            case TTimestamp: "TIMESTAMP";
            case TYear: "YEAR";
            case TJson: "JSON";
            case TBinary: "BLOB";
            case TUuid: "CHAR(36)";
            case TEnum: 'ENUM(${quotedValueList(column.allowed)})';
            case TSet: 'SET(${quotedValueList(column.allowed)})';
            case TGeometry: geometryTypeSql(column);
        }

        if (column.isUnsigned && column.type != TIncrements && column.type != TBigIncrements)
            sql += " UNSIGNED";

        return sql;
    }

    private function geometryTypeSql(column:ColumnDefinition):String {
        var sql = SchemaGrammar.asciiUpper(column.subtype ?? "geometry");
        if (column.srid != null)
            sql += ' SRID ${column.srid}';
        return sql;
    }

    private function quotedValueList(values:Array<String>):String {
        return values.map(value -> "'" + escapeString(value) + "'").join(", ");
    }

    private override function charsetModifier(column:ColumnDefinition):String {
        if (column.charsetName != null)
            return ' CHARACTER SET ${column.charsetName}';
        return "";
    }

    private override function nullableModifier(column:ColumnDefinition):String {
        if (column.virtualAsExpr != null || column.storedAsExpr != null)
            return column.isNullable ? "" : " NOT NULL";
        return column.isNullable ? " NULL" : " NOT NULL";
    }

    private override function onUpdateModifier(column:ColumnDefinition):String {
        if (column.usesCurrentOnUpdate)
            return " ON UPDATE CURRENT_TIMESTAMP";
        return "";
    }

    private override function incrementModifier(column:ColumnDefinition, blueprint:Null<Blueprint>):String {
        if (!isIncrementsColumn(column))
            return "";
        if (hasPrimaryCommand(blueprint) || (column.isChange && !column.isPrimary))
            return " AUTO_INCREMENT";
        return " AUTO_INCREMENT PRIMARY KEY";
    }

    private override function commentModifier(column:ColumnDefinition):String {
        if (column.commentText != null)
            return ' COMMENT \'${escapeString(column.commentText)}\'';
        return "";
    }

    private override function placementModifier(column:ColumnDefinition):String {
        if (column.isFirst)
            return " FIRST";
        if (column.afterColumn != null)
            return ' AFTER ${quote(column.afterColumn)}';
        return "";
    }

    private override function tableOptionsSql(blueprint:Blueprint):String {
        var sql = "";
        if (blueprint.engineName != null)
            sql += ' ENGINE = ${blueprint.engineName}';
        if (blueprint.tableCharset != null)
            sql += ' DEFAULT CHARACTER SET ${blueprint.tableCharset}';
        if (blueprint.tableCollation != null)
            sql += ' COLLATE ${blueprint.tableCollation}';
        if (blueprint.tableComment != null)
            sql += ' COMMENT = \'${escapeString(blueprint.tableComment)}\'';
        return sql;
    }

    private override function compileChangeColumn(table:String, column:ColumnDefinition):String {
        return 'ALTER TABLE ${quote(table)} MODIFY ${compileColumnDefinition(column)}';
    }

    private override function compileUnique(table:String, columns:Array<String>, name:String):String {
        return 'ALTER TABLE ${quote(table)} ADD UNIQUE ${quote(name)} (${quoteList(columns)})';
    }

    private override function compileIndex(table:String, columns:Array<String>, name:String):String {
        return 'ALTER TABLE ${quote(table)} ADD INDEX ${quote(name)} (${quoteList(columns)})';
    }

    private override function compileFullText(table:String, columns:Array<String>, name:String):String {
        return 'ALTER TABLE ${quote(table)} ADD FULLTEXT ${quote(name)} (${quoteList(columns)})';
    }

    private override function compileSpatialIndex(table:String, columns:Array<String>, name:String):String {
        return 'ALTER TABLE ${quote(table)} ADD SPATIAL INDEX ${quote(name)} (${quoteList(columns)})';
    }

    private override function compileRenameIndex(table:String, from:String, to:String):String {
        return 'ALTER TABLE ${quote(table)} RENAME INDEX ${quote(from)} TO ${quote(to)}';
    }

    private override function compileAddPrimary(table:String, columns:Array<String>, name:Null<String>):String {
        return 'ALTER TABLE ${quote(table)} ADD PRIMARY KEY (${quoteList(columns)})';
    }

    private override function compileAddForeign(table:String, foreign:ForeignKeyDefinition):String {
        return 'ALTER TABLE ${quote(table)} ADD ${foreignSql(table, foreign)}';
    }

    private override function compileDropIndex(table:String, name:String):String {
        return 'ALTER TABLE ${quote(table)} DROP INDEX ${quote(name)}';
    }

    private override function compileDropPrimary(table:String):String {
        return 'ALTER TABLE ${quote(table)} DROP PRIMARY KEY';
    }

    private override function compileDropForeign(table:String, name:String):String {
        return 'ALTER TABLE ${quote(table)} DROP FOREIGN KEY ${quote(name)}';
    }

    public override function compileRename(from:String, to:String):String {
        return 'RENAME TABLE ${quote(from)} TO ${quote(to)}';
    }

    public override function compileTableExists(table:String):String {
        return 'SELECT TABLE_NAME AS name FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = \'${escapeString(table)}\'';
    }

    public override function compileColumnListing(table:String):String {
        return 'SELECT COLUMN_NAME AS name FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = \'${escapeString(table)}\'';
    }

    public override function compileTableListing():String {
        return 'SELECT TABLE_NAME AS name FROM information_schema.tables WHERE table_schema = DATABASE()';
    }

    public override function compileIndexListing(table:String):String {
        return 'SELECT DISTINCT INDEX_NAME AS name FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = \'${escapeString(table)}\'';
    }

    public override function compileEnableForeignKeyConstraints():String {
        return "SET FOREIGN_KEY_CHECKS = 1";
    }

    public override function compileDisableForeignKeyConstraints():String {
        return "SET FOREIGN_KEY_CHECKS = 0";
    }

    public override function compileCreateDatabase(name:String):String {
        return 'CREATE DATABASE ${quote(name)}';
    }

    public override function compileDropDatabaseIfExists(name:String):String {
        return 'DROP DATABASE IF EXISTS ${quote(name)}';
    }
}
