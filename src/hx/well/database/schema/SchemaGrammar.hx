package hx.well.database.schema;

import haxe.Exception;
import hx.well.database.query.QueryIdentifier;
using StringTools;

class SchemaGrammar {
    public function new() {}

    public function compileCreate(blueprint:Blueprint):Array<String> {
        var definitions:Array<String> = [for (column in blueprint.columns) columnSql(column, blueprint)];

        var primaryColumns:Array<String> = [
            for (column in blueprint.columns)
                if (column.isPrimary && !isIncrementsColumn(column)) column.name
        ];
        for (command in blueprint.commands) {
            switch (command) {
                case AddPrimary(columns, _):
                    primaryColumns = primaryColumns.concat(columns);
                default:
            }
        }
        if (primaryColumns.length > 0)
            definitions.push('PRIMARY KEY (${quoteList(primaryColumns)})');

        for (command in blueprint.commands) {
            switch (command) {
                case AddForeign(foreign):
                    definitions.push(foreignSql(blueprint.table, foreign));
                default:
            }
        }

        var create = blueprint.isTemporary ? "CREATE TEMPORARY TABLE" : "CREATE TABLE";
        var statements = ['${create} ${quote(blueprint.table)} (${definitions.join(", ")})${tableOptionsSql(blueprint)}'];
        return statements.concat(indexStatements(blueprint));
    }

    public function compileAlter(blueprint:Blueprint):Array<String> {
        var statements:Array<String> = [
            for (column in blueprint.columns)
                if (column.isChange)
                    compileChangeColumn(blueprint.table, column)
                else
                    'ALTER TABLE ${quote(blueprint.table)} ADD COLUMN ${columnSql(column, blueprint)}'
        ];

        statements = statements.concat(indexStatements(blueprint));

        for (command in blueprint.commands) {
            switch (command) {
                case AddPrimary(columns, name):
                    statements.push(compileAddPrimary(blueprint.table, columns, name));
                case AddForeign(foreign):
                    statements.push(compileAddForeign(blueprint.table, foreign));
                case DropColumn(columns):
                    for (column in columns)
                        statements.push('ALTER TABLE ${quote(blueprint.table)} DROP COLUMN ${quote(column)}');
                case RenameColumn(from, to):
                    statements.push('ALTER TABLE ${quote(blueprint.table)} RENAME COLUMN ${quote(from)} TO ${quote(to)}');
                case RenameIndex(from, to):
                    statements.push(compileRenameIndex(blueprint.table, from, to));
                case DropIndex(name) | DropUnique(name) | DropFullText(name) | DropSpatialIndex(name):
                    statements.push(compileDropIndex(blueprint.table, name));
                case DropPrimary:
                    statements.push(compileDropPrimary(blueprint.table));
                case DropForeign(name):
                    statements.push(compileDropForeign(blueprint.table, name));
                case AddUnique(_, _) | AddIndex(_, _) | AddFullText(_, _) | AddSpatialIndex(_, _):
            }
        }

        return statements;
    }

    public function compileDrop(table:String):String {
        return 'DROP TABLE ${quote(table)}';
    }

    public function compileDropIfExists(table:String):String {
        return 'DROP TABLE IF EXISTS ${quote(table)}';
    }

    public function compileRename(from:String, to:String):String {
        throw new Exception("Not implemented");
    }

    public function compileTableExists(table:String):String {
        throw new Exception("Not implemented");
    }

    public function compileColumnListing(table:String):String {
        throw new Exception("Not implemented");
    }

    public function compileTableListing():String {
        throw new Exception("Not implemented");
    }

    public function compileIndexListing(table:String):String {
        throw new Exception("Not implemented");
    }

    public function compileCreateDatabase(name:String):String {
        throw new Exception("Not implemented");
    }

    public function compileDropDatabaseIfExists(name:String):String {
        throw new Exception("Not implemented");
    }

    public function compileEnableForeignKeyConstraints():String {
        throw new Exception("Not implemented");
    }

    public function compileDisableForeignKeyConstraints():String {
        throw new Exception("Not implemented");
    }

    public function compileColumnDefinition(column:ColumnDefinition):String {
        return columnSql(column, null);
    }

    public function compileColumnIndexes(table:String, column:ColumnDefinition):Array<String> {
        var statements:Array<String> = [];
        if (column.isUnique)
            statements.push(compileUnique(table, [column.name], column.uniqueName ?? indexName(table, [column.name], "unique")));
        if (column.hasIndex)
            statements.push(compileIndex(table, [column.name], column.indexName ?? indexName(table, [column.name], "index")));
        if (column.isFullText)
            statements.push(compileFullText(table, [column.name], column.fullTextName ?? indexName(table, [column.name], "fulltext")));
        if (column.isSpatialIndex)
            statements.push(compileSpatialIndex(table, [column.name], column.spatialIndexName ?? indexName(table, [column.name], "spatialindex")));
        return statements;
    }

    private function indexStatements(blueprint:Blueprint):Array<String> {
        var statements:Array<String> = [];

        for (column in blueprint.columns)
            statements = statements.concat(compileColumnIndexes(blueprint.table, column));

        for (command in blueprint.commands) {
            switch (command) {
                case AddUnique(columns, name):
                    statements.push(compileUnique(blueprint.table, columns, name ?? indexName(blueprint.table, columns, "unique")));
                case AddIndex(columns, name):
                    statements.push(compileIndex(blueprint.table, columns, name ?? indexName(blueprint.table, columns, "index")));
                case AddFullText(columns, name):
                    statements.push(compileFullText(blueprint.table, columns, name ?? indexName(blueprint.table, columns, "fulltext")));
                case AddSpatialIndex(columns, name):
                    statements.push(compileSpatialIndex(blueprint.table, columns, name ?? indexName(blueprint.table, columns, "spatialindex")));
                default:
            }
        }

        return statements;
    }

    private function columnSql(column:ColumnDefinition, blueprint:Null<Blueprint>):String {
        return '${quote(column.name)} ${typeSql(column)}${modifierSql(column, blueprint)}';
    }

    private function typeSql(column:ColumnDefinition):String {
        throw new Exception("Not implemented");
    }

    private function modifierSql(column:ColumnDefinition, blueprint:Null<Blueprint>):String {
        var sql = "";
        sql += charsetModifier(column);
        sql += collateModifier(column);
        sql += generatedModifier(column);
        sql += nullableModifier(column);
        if (column.usesCurrent)
            sql += " DEFAULT CURRENT_TIMESTAMP";
        else if (column.hasDefault)
            sql += ' DEFAULT ${formatDefault(column.defaultVal)}';
        sql += onUpdateModifier(column);
        sql += incrementModifier(column, blueprint);
        sql += commentModifier(column);
        sql += placementModifier(column);
        return sql;
    }

    private function charsetModifier(column:ColumnDefinition):String {
        return "";
    }

    private function collateModifier(column:ColumnDefinition):String {
        if (column.collationName != null)
            return ' COLLATE ${column.collationName}';
        return "";
    }

    private function generatedModifier(column:ColumnDefinition):String {
        if (column.virtualAsExpr != null)
            return ' AS (${column.virtualAsExpr}) VIRTUAL';
        if (column.storedAsExpr != null)
            return ' AS (${column.storedAsExpr}) STORED';
        return "";
    }

    private function nullableModifier(column:ColumnDefinition):String {
        return column.isNullable ? "" : " NOT NULL";
    }

    private function onUpdateModifier(column:ColumnDefinition):String {
        return "";
    }

    private function incrementModifier(column:ColumnDefinition, blueprint:Null<Blueprint>):String {
        return "";
    }

    private function commentModifier(column:ColumnDefinition):String {
        return "";
    }

    private function placementModifier(column:ColumnDefinition):String {
        return "";
    }

    private function tableOptionsSql(blueprint:Blueprint):String {
        return "";
    }

    private function compileChangeColumn(table:String, column:ColumnDefinition):String {
        throw new Exception("Not implemented");
    }

    private function compileUnique(table:String, columns:Array<String>, name:String):String {
        throw new Exception("Not implemented");
    }

    private function compileIndex(table:String, columns:Array<String>, name:String):String {
        throw new Exception("Not implemented");
    }

    private function compileFullText(table:String, columns:Array<String>, name:String):String {
        throw new Exception("Not implemented");
    }

    private function compileSpatialIndex(table:String, columns:Array<String>, name:String):String {
        throw new Exception("Not implemented");
    }

    private function compileRenameIndex(table:String, from:String, to:String):String {
        throw new Exception("Not implemented");
    }

    private function compileAddPrimary(table:String, columns:Array<String>, name:Null<String>):String {
        throw new Exception("Not implemented");
    }

    private function compileAddForeign(table:String, foreign:ForeignKeyDefinition):String {
        throw new Exception("Not implemented");
    }

    private function compileDropIndex(table:String, name:String):String {
        throw new Exception("Not implemented");
    }

    private function compileDropPrimary(table:String):String {
        throw new Exception("Not implemented");
    }

    private function compileDropForeign(table:String, name:String):String {
        throw new Exception("Not implemented");
    }

    private function foreignSql(table:String, foreign:ForeignKeyDefinition):String {
        if (foreign.referencedTable == null)
            throw new Exception('Foreign key on ${table} (${foreign.columns.join(", ")}) requires on() to define the referenced table.');

        var name = foreign.name ?? indexName(table, foreign.columns, "foreign");
        var sql = 'CONSTRAINT ${quote(name)} FOREIGN KEY (${quoteList(foreign.columns)}) REFERENCES ${quote(foreign.referencedTable)} (${quoteList(foreign.referencedColumns)})';
        if (foreign.onDeleteAction != null)
            sql += ' ON DELETE ${asciiUpper(foreign.onDeleteAction)}';
        if (foreign.onUpdateAction != null)
            sql += ' ON UPDATE ${asciiUpper(foreign.onUpdateAction)}';
        return sql;
    }

    public function isIncrementsColumn(column:ColumnDefinition):Bool {
        return column.type == TIncrements || column.type == TBigIncrements || column.isAutoIncrement;
    }

    private function hasPrimaryCommand(blueprint:Null<Blueprint>):Bool {
        if (blueprint == null)
            return false;
        for (command in blueprint.commands) {
            switch (command) {
                case AddPrimary(_, _): return true;
                default:
            }
        }
        return false;
    }

    private function indexName(table:String, columns:Array<String>, suffix:String):String {
        return asciiLower('${table}_${columns.join("_")}_${suffix}');
    }

    private function formatDefault(value:Dynamic):String {
        if (value == null)
            return "NULL";
        if (value is Bool)
            return (value : Bool) ? "1" : "0";
        if (value is Int || value is Float)
            return Std.string(value);
        return "'" + Std.string(value).replace("'", "''") + "'";
    }

    public static function asciiUpper(value:String):String {
        var buf = new StringBuf();
        for (i in 0...value.length) {
            var code = value.charCodeAt(i);
            if (code >= 'a'.code && code <= 'z'.code)
                code -= 32;
            buf.addChar(code);
        }
        return buf.toString();
    }

    public static function asciiLower(value:String):String {
        var buf = new StringBuf();
        for (i in 0...value.length) {
            var code = value.charCodeAt(i);
            if (code >= 'A'.code && code <= 'Z'.code)
                code += 32;
            buf.addChar(code);
        }
        return buf.toString();
    }

    private function quote(identifier:String):String {
        return QueryIdentifier.quote(identifier);
    }

    private function quoteList(identifiers:Array<String>):String {
        return identifiers.map(quote).join(", ");
    }

    private function escapeString(value:String):String {
        return value.replace("'", "''");
    }
}
