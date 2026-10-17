package hx.well.database.schema;

import haxe.Exception;
import hx.well.database.Connection;
import sys.FileSystem;
import sys.io.File;
using StringTools;

class SchemaBuilder {
    public static var defaultStringLength:Int = 255;

    private var connectionKey:String;

    public function new(connectionKey:String = "default") {
        this.connectionKey = connectionKey;
    }

    private function grammar():SchemaGrammar {
        return switch (Connection.driver(connectionKey)) {
            case "sqlite": new SqliteSchemaGrammar();
            case "mysql": new MysqlSchemaGrammar();
            case driver: throw new Exception('No schema grammar available for driver: ${driver}');
        }
    }

    private function isSqlite():Bool {
        return Connection.driver(connectionKey) == "sqlite";
    }

    private function request(statement:String):sys.db.ResultSet {
        return Connection.get(connectionKey).request(statement);
    }

    private function execute(statements:Array<String>):Void {
        for (statement in statements)
            request(statement);
    }

    public function create(table:String, callback:Blueprint->Void):Void {
        var blueprint = new Blueprint(table);
        callback(blueprint);
        execute(grammar().compileCreate(blueprint));
    }

    public function table(table:String, callback:Blueprint->Void):Void {
        var blueprint = new Blueprint(table);
        callback(blueprint);

        if (isSqlite()) {
            var changedColumns = blueprint.columns.filter(column -> column.isChange);
            var renames:Array<{from:String, to:String}> = [];
            blueprint.columns = blueprint.columns.filter(column -> !column.isChange);
            blueprint.commands = blueprint.commands.filter(command -> switch (command) {
                case RenameIndex(from, to):
                    renames.push({from: from, to: to});
                    false;
                default:
                    true;
            });

            execute(grammar().compileAlter(blueprint));

            for (rename in renames)
                sqliteRenameIndex(table, rename.from, rename.to);

            if (changedColumns.length > 0)
                sqliteChangeColumns(table, changedColumns);
            return;
        }

        execute(grammar().compileAlter(blueprint));
    }

    public function drop(table:String):Void {
        execute([grammar().compileDrop(table)]);
    }

    public function dropIfExists(table:String):Void {
        execute([grammar().compileDropIfExists(table)]);
    }

    public function dropColumns(table:String, columns:Array<String>):Void {
        this.table(table, blueprint -> blueprint.dropColumn(columns));
    }

    public function dropAllTables():Void {
        disableForeignKeyConstraints();
        try {
            for (table in getTableListing())
                drop(table);
        } catch (e:Dynamic) {
            enableForeignKeyConstraints();
            throw e;
        }
        enableForeignKeyConstraints();
    }

    public function rename(from:String, to:String):Void {
        execute([grammar().compileRename(from, to)]);
    }

    public function hasTable(table:String):Bool {
        return request(grammar().compileTableExists(table)).hasNext();
    }

    public function hasColumn(table:String, column:String):Bool {
        return getColumnListing(table).map(SchemaGrammar.asciiLower).contains(SchemaGrammar.asciiLower(column));
    }

    public function hasColumns(table:String, columns:Array<String>):Bool {
        var existing = getColumnListing(table).map(SchemaGrammar.asciiLower);
        for (column in columns) {
            if (!existing.contains(SchemaGrammar.asciiLower(column)))
                return false;
        }
        return true;
    }

    public function hasIndex(table:String, index:String):Bool {
        return getIndexListing(table).map(SchemaGrammar.asciiLower).contains(SchemaGrammar.asciiLower(index));
    }

    public function getColumnListing(table:String):Array<String> {
        return readNames(grammar().compileColumnListing(table));
    }

    public function getIndexListing(table:String):Array<String> {
        return readNames(grammar().compileIndexListing(table));
    }

    public function getTableListing():Array<String> {
        return readNames(grammar().compileTableListing());
    }

    public function whenTableHasColumn(table:String, column:String, callback:Blueprint->Void):Void {
        if (hasColumn(table, column))
            this.table(table, callback);
    }

    public function whenTableDoesntHaveColumn(table:String, column:String, callback:Blueprint->Void):Void {
        if (!hasColumn(table, column))
            this.table(table, callback);
    }

    public function createDatabase(name:String):Void {
        if (isSqlite()) {
            if (!FileSystem.exists(name))
                File.saveContent(name, "");
            return;
        }

        execute([grammar().compileCreateDatabase(name)]);
    }

    public function dropDatabaseIfExists(name:String):Void {
        if (isSqlite()) {
            if (FileSystem.exists(name))
                FileSystem.deleteFile(name);
            return;
        }

        execute([grammar().compileDropDatabaseIfExists(name)]);
    }

    public function enableForeignKeyConstraints():Void {
        execute([grammar().compileEnableForeignKeyConstraints()]);
    }

    public function disableForeignKeyConstraints():Void {
        execute([grammar().compileDisableForeignKeyConstraints()]);
    }

    public function withoutForeignKeyConstraints(callback:()->Void):Void {
        disableForeignKeyConstraints();
        try {
            callback();
        } catch (e:Dynamic) {
            enableForeignKeyConstraints();
            throw e;
        }
        enableForeignKeyConstraints();
    }

    private function readNames(statement:String):Array<String> {
        var resultSet = request(statement);
        return [for (row in resultSet.results()) Std.string(Reflect.field(row, "name"))];
    }

    private function intValue(value:Dynamic):Int {
        return Std.parseInt(Std.string(value)) ?? 0;
    }

    private function quote(identifier:String):String {
        return hx.well.database.query.QueryIdentifier.quote(identifier);
    }

    private function sqliteRenameIndex(table:String, from:String, to:String):Void {
        var indexRow:Dynamic = null;
        for (row in request('PRAGMA index_list(${quote(table)})').results()) {
            if (Std.string(Reflect.field(row, "name")) == from)
                indexRow = row;
        }

        if (indexRow == null)
            throw new Exception('Index ${from} does not exist on table ${table}.');

        var createSql:Null<String> = null;
        for (row in request('SELECT sql FROM sqlite_master WHERE type = \'index\' AND name = \'${from.replace("'", "''")}\'').results()) {
            if (Reflect.field(row, "sql") != null)
                createSql = Std.string(Reflect.field(row, "sql"));
        }
        if (createSql == null)
            throw new Exception("SQLite does not support renaming an implicit primary or unique index.");
        var renamedSql = SqliteTableDefinition.renameIndex(createSql, to);

        sqliteTransaction(() -> {
            request('DROP INDEX ${quote(from)}');
            request(renamedSql);
        });
    }

    private function sqliteChangeColumns(table:String, changedColumns:Array<ColumnDefinition>):Void {
        var schemaGrammar = grammar();
        var definition = SqliteTableDefinition.parse(sqliteTableSql(table));
        var changedByName:Map<String, ColumnDefinition> = [for (column in changedColumns) SchemaGrammar.asciiLower(column.name) => column];

        var columnRows = [for (row in request('PRAGMA table_xinfo(${quote(table)})').results()) row];
        columnRows.sort((a, b) -> intValue(Reflect.field(a, "cid")) - intValue(Reflect.field(b, "cid")));
        var existingColumns = [for (row in columnRows) SchemaGrammar.asciiLower(Std.string(Reflect.field(row, "name")))];
        for (column in changedColumns) {
            if (!existingColumns.contains(SchemaGrammar.asciiLower(column.name)))
                throw new Exception('Column ${column.name} does not exist on table ${table}.');
        }

        var hasPrimaryConstraint = false;
        var definitions:Array<String> = [];
        for (item in definition.items) {
            var name = SqliteTableDefinition.columnName(item);
            if (name == null) {
                if (SqliteTableDefinition.isPrimaryKeyConstraint(item))
                    hasPrimaryConstraint = true;
                definitions.push(item);
                continue;
            }
            var changed = changedByName.get(SchemaGrammar.asciiLower(name));
            definitions.push(changed != null ? schemaGrammar.compileColumnDefinition(changed) : item);
        }

        var primaryColumns:Array<String> = [];
        var copyColumns:Array<String> = [];
        for (row in columnRows) {
            var name = Std.string(Reflect.field(row, "name"));
            var changed = changedByName.get(SchemaGrammar.asciiLower(name));
            if (changed == null) {
                if (intValue(Reflect.field(row, "hidden")) == 0)
                    copyColumns.push(name);
                continue;
            }
            if (!isGeneratedColumn(changed))
                copyColumns.push(name);
            if (!hasPrimaryConstraint && !schemaGrammar.isIncrementsColumn(changed) && (changed.isPrimary || intValue(Reflect.field(row, "pk")) > 0))
                primaryColumns.push(name);
        }
        if (primaryColumns.length > 0)
            definitions.push('PRIMARY KEY (${primaryColumns.map(quote).join(", ")})');

        var dependentSql:Array<String> = [
            for (row in request('SELECT sql FROM sqlite_master WHERE type IN (\'index\', \'trigger\') AND tbl_name = \'${table.replace("'", "''")}\' AND sql IS NOT NULL').results())
                Std.string(Reflect.field(row, "sql"))
        ];

        var indexStatements:Array<String> = [];
        for (column in changedColumns)
            indexStatements = indexStatements.concat(schemaGrammar.compileColumnIndexes(table, column));

        var temporaryTable = '__tmp_${table}';
        var quotedColumns = copyColumns.map(quote).join(", ");
        var suffix = definition.suffix == "" ? "" : ' ${definition.suffix}';

        sqliteWithoutForeignKeys(() -> sqliteTransaction(() -> {
            request('CREATE TABLE ${quote(temporaryTable)} (${definitions.join(", ")})${suffix}');
            if (copyColumns.length > 0)
                request('INSERT INTO ${quote(temporaryTable)} (${quotedColumns}) SELECT ${quotedColumns} FROM ${quote(table)}');
            // Keep AUTOINCREMENT's high-water mark even when the highest rows were deleted.
            if (request("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'sqlite_sequence'").hasNext())
                request('UPDATE sqlite_sequence SET seq = MAX(seq, COALESCE((SELECT seq FROM sqlite_sequence WHERE name = \'${table.replace("'", "''")}\'), 0)) WHERE name = \'${temporaryTable.replace("'", "''")}\'');
            request('DROP TABLE ${quote(table)}');
            request('ALTER TABLE ${quote(temporaryTable)} RENAME TO ${quote(table)}');
            for (sql in dependentSql)
                request(sql);
            for (statement in indexStatements)
                request(statement);
        }));
    }

    private function isGeneratedColumn(column:ColumnDefinition):Bool {
        return column.storedAsExpr != null || column.virtualAsExpr != null;
    }

    private function sqliteTableSql(table:String):String {
        for (row in request('SELECT sql FROM sqlite_master WHERE type = \'table\' AND name = \'${table.replace("'", "''")}\'').results())
            return Std.string(Reflect.field(row, "sql"));
        throw new Exception('Table ${table} does not exist.');
    }

    private function sqliteTransaction(callback:()->Void):Void {
        request("SAVEPOINT hxwell_schema");
        try {
            callback();
        } catch (e:Dynamic) {
            request("ROLLBACK TO SAVEPOINT hxwell_schema");
            request("RELEASE SAVEPOINT hxwell_schema");
            throw e;
        }
        request("RELEASE SAVEPOINT hxwell_schema");
    }

    private function sqliteWithoutForeignKeys(callback:()->Void):Void {
        var enabled = false;
        for (row in request("PRAGMA foreign_keys").results())
            enabled = intValue(Reflect.field(row, "foreign_keys")) == 1;
        if (!enabled) {
            callback();
            return;
        }

        request("PRAGMA foreign_keys = OFF");
        for (row in request("PRAGMA foreign_keys").results()) {
            if (intValue(Reflect.field(row, "foreign_keys")) != 0)
                throw new Exception("SQLite column changes with foreign keys enabled must run outside an active transaction.");
        }
        try {
            callback();
        } catch (e:Dynamic) {
            request("PRAGMA foreign_keys = ON");
            throw e;
        }
        request("PRAGMA foreign_keys = ON");
    }
}
