package hx.well.database.schema;

class Blueprint {
    public var table(default, null):String;
    public var columns:Array<ColumnDefinition> = [];
    public var commands:Array<SchemaCommand> = [];
    public var engineName:Null<String>;
    public var tableCharset:Null<String>;
    public var tableCollation:Null<String>;
    public var tableComment:Null<String>;
    public var isTemporary:Bool = false;

    public function new(table:String) {
        this.table = table;
    }

    private function addColumn(name:String, type:ColumnType):ColumnDefinition {
        var column = new ColumnDefinition(name, type);
        columns.push(column);
        return column;
    }

    private function addForeignIdColumn(name:String, type:ColumnType):ForeignIdColumnDefinition {
        var column = new ForeignIdColumnDefinition(this, name, type);
        columns.push(column);
        return column;
    }

    public function temporary():Blueprint {
        isTemporary = true;
        return this;
    }

    public function engine(engine:String):Blueprint {
        engineName = engine;
        return this;
    }

    public function charset(charset:String):Blueprint {
        tableCharset = charset;
        return this;
    }

    public function collation(collation:String):Blueprint {
        tableCollation = collation;
        return this;
    }

    public function comment(comment:String):Blueprint {
        tableComment = comment;
        return this;
    }

    public function id(column:String = "id"):ColumnDefinition {
        return bigIncrements(column);
    }

    public function increments(column:String):ColumnDefinition {
        return addColumn(column, TIncrements);
    }

    public function tinyIncrements(column:String):ColumnDefinition {
        return tinyInteger(column).unsigned().autoIncrement();
    }

    public function smallIncrements(column:String):ColumnDefinition {
        return smallInteger(column).unsigned().autoIncrement();
    }

    public function mediumIncrements(column:String):ColumnDefinition {
        return mediumInteger(column).unsigned().autoIncrement();
    }

    public function bigIncrements(column:String):ColumnDefinition {
        return addColumn(column, TBigIncrements);
    }

    public function integer(column:String):ColumnDefinition {
        return addColumn(column, TInteger);
    }

    public function tinyInteger(column:String):ColumnDefinition {
        return addColumn(column, TTinyInteger);
    }

    public function smallInteger(column:String):ColumnDefinition {
        return addColumn(column, TSmallInteger);
    }

    public function mediumInteger(column:String):ColumnDefinition {
        return addColumn(column, TMediumInteger);
    }

    public function bigInteger(column:String):ColumnDefinition {
        return addColumn(column, TBigInteger);
    }

    public function unsignedInteger(column:String):ColumnDefinition {
        return integer(column).unsigned();
    }

    public function unsignedTinyInteger(column:String):ColumnDefinition {
        return tinyInteger(column).unsigned();
    }

    public function unsignedSmallInteger(column:String):ColumnDefinition {
        return smallInteger(column).unsigned();
    }

    public function unsignedMediumInteger(column:String):ColumnDefinition {
        return mediumInteger(column).unsigned();
    }

    public function unsignedBigInteger(column:String):ColumnDefinition {
        return bigInteger(column).unsigned();
    }

    public function foreignId(column:String):ForeignIdColumnDefinition {
        var definition = addForeignIdColumn(column, TBigInteger);
        definition.isUnsigned = true;
        return definition;
    }

    public function foreignUuid(column:String):ForeignIdColumnDefinition {
        return addForeignIdColumn(column, TUuid);
    }

    public function foreignUlid(column:String):ForeignIdColumnDefinition {
        var definition = addForeignIdColumn(column, TChar);
        definition.length = 26;
        return definition;
    }

    public function string(column:String, ?length:Int):ColumnDefinition {
        var definition = addColumn(column, TString);
        definition.length = length ?? SchemaBuilder.defaultStringLength;
        return definition;
    }

    public function char(column:String, ?length:Int):ColumnDefinition {
        var definition = addColumn(column, TChar);
        definition.length = length ?? SchemaBuilder.defaultStringLength;
        return definition;
    }

    public function text(column:String):ColumnDefinition {
        return addColumn(column, TText);
    }

    public function mediumText(column:String):ColumnDefinition {
        return addColumn(column, TMediumText);
    }

    public function longText(column:String):ColumnDefinition {
        return addColumn(column, TLongText);
    }

    public function boolean(column:String):ColumnDefinition {
        return addColumn(column, TBoolean);
    }

    public function float(column:String, precision:Int = 53):ColumnDefinition {
        var definition = addColumn(column, TFloat);
        definition.precision = precision;
        return definition;
    }

    public function double(column:String):ColumnDefinition {
        return addColumn(column, TDouble);
    }

    public function decimal(column:String, total:Int = 8, places:Int = 2):ColumnDefinition {
        var definition = addColumn(column, TDecimal);
        definition.total = total;
        definition.places = places;
        return definition;
    }

    public function unsignedDecimal(column:String, total:Int = 8, places:Int = 2):ColumnDefinition {
        return decimal(column, total, places).unsigned();
    }

    public function date(column:String):ColumnDefinition {
        return addColumn(column, TDate);
    }

    public function dateTime(column:String):ColumnDefinition {
        return addColumn(column, TDateTime);
    }

    public function dateTimeTz(column:String):ColumnDefinition {
        return dateTime(column);
    }

    public function time(column:String):ColumnDefinition {
        return addColumn(column, TTime);
    }

    public function timeTz(column:String):ColumnDefinition {
        return time(column);
    }

    public function timestamp(column:String):ColumnDefinition {
        return addColumn(column, TTimestamp);
    }

    public function timestampTz(column:String):ColumnDefinition {
        return timestamp(column);
    }

    public function year(column:String):ColumnDefinition {
        return addColumn(column, TYear);
    }

    public function timestamps():Void {
        timestamp("created_at").nullable();
        timestamp("updated_at").nullable();
    }

    public function timestampsTz():Void {
        timestamps();
    }

    public function nullableTimestamps():Void {
        timestamps();
    }

    public function datetimes():Void {
        dateTime("created_at").nullable();
        dateTime("updated_at").nullable();
    }

    public function softDeletes(column:String = "deleted_at"):ColumnDefinition {
        return timestamp(column).nullable();
    }

    public function softDeletesTz(column:String = "deleted_at"):ColumnDefinition {
        return softDeletes(column);
    }

    public function json(column:String):ColumnDefinition {
        return addColumn(column, TJson);
    }

    public function jsonb(column:String):ColumnDefinition {
        return addColumn(column, TJson);
    }

    public function binary(column:String):ColumnDefinition {
        return addColumn(column, TBinary);
    }

    public function uuid(column:String = "uuid"):ColumnDefinition {
        return addColumn(column, TUuid);
    }

    public function ulid(column:String = "ulid"):ColumnDefinition {
        return char(column, 26);
    }

    public function ipAddress(column:String = "ip_address"):ColumnDefinition {
        return string(column, 45);
    }

    public function macAddress(column:String = "mac_address"):ColumnDefinition {
        return string(column, 17);
    }

    public function enumeration(column:String, allowed:Array<String>):ColumnDefinition {
        var definition = addColumn(column, TEnum);
        definition.allowed = allowed;
        return definition;
    }

    public function set(column:String, allowed:Array<String>):ColumnDefinition {
        var definition = addColumn(column, TSet);
        definition.allowed = allowed;
        return definition;
    }

    public function geometry(column:String, ?subtype:String, ?srid:Int):ColumnDefinition {
        var definition = addColumn(column, TGeometry);
        definition.subtype = subtype;
        definition.srid = srid;
        return definition;
    }

    public function geography(column:String, ?subtype:String, srid:Int = 4326):ColumnDefinition {
        return geometry(column, subtype, srid);
    }

    public function point(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "point", srid);
    }

    public function lineString(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "linestring", srid);
    }

    public function polygon(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "polygon", srid);
    }

    public function multiPoint(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "multipoint", srid);
    }

    public function multiLineString(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "multilinestring", srid);
    }

    public function multiPolygon(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "multipolygon", srid);
    }

    public function geometryCollection(column:String, ?srid:Int):ColumnDefinition {
        return geometry(column, "geometrycollection", srid);
    }

    public function morphs(name:String, ?indexName:String):Void {
        string('${name}_type');
        unsignedBigInteger('${name}_id');
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function nullableMorphs(name:String, ?indexName:String):Void {
        string('${name}_type').nullable();
        unsignedBigInteger('${name}_id').nullable();
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function uuidMorphs(name:String, ?indexName:String):Void {
        string('${name}_type');
        uuid('${name}_id');
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function nullableUuidMorphs(name:String, ?indexName:String):Void {
        string('${name}_type').nullable();
        uuid('${name}_id').nullable();
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function ulidMorphs(name:String, ?indexName:String):Void {
        string('${name}_type');
        ulid('${name}_id');
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function nullableUlidMorphs(name:String, ?indexName:String):Void {
        string('${name}_type').nullable();
        ulid('${name}_id').nullable();
        index(['${name}_type', '${name}_id'], indexName);
    }

    public function rememberToken():ColumnDefinition {
        return string("remember_token", 100).nullable();
    }

    public overload extern inline function primary(column:String, ?name:String):Void {
        primary([column], name);
    }

    public overload extern inline function primary(columns:Array<String>, ?name:String):Void {
        commands.push(AddPrimary(columns, name));
    }

    public overload extern inline function unique(column:String, ?name:String):Void {
        unique([column], name);
    }

    public overload extern inline function unique(columns:Array<String>, ?name:String):Void {
        commands.push(AddUnique(columns, name));
    }

    public overload extern inline function index(column:String, ?name:String):Void {
        index([column], name);
    }

    public overload extern inline function index(columns:Array<String>, ?name:String):Void {
        commands.push(AddIndex(columns, name));
    }

    public overload extern inline function fullText(column:String, ?name:String):Void {
        fullText([column], name);
    }

    public overload extern inline function fullText(columns:Array<String>, ?name:String):Void {
        commands.push(AddFullText(columns, name));
    }

    public overload extern inline function spatialIndex(column:String, ?name:String):Void {
        spatialIndex([column], name);
    }

    public overload extern inline function spatialIndex(columns:Array<String>, ?name:String):Void {
        commands.push(AddSpatialIndex(columns, name));
    }

    public overload extern inline function foreign(column:String, ?name:String):ForeignKeyDefinition {
        return foreign([column], name);
    }

    public overload extern inline function foreign(columns:Array<String>, ?name:String):ForeignKeyDefinition {
        var definition = new ForeignKeyDefinition(columns, name);
        commands.push(AddForeign(definition));
        return definition;
    }

    public overload extern inline function dropColumn(column:String):Void {
        dropColumn([column]);
    }

    public overload extern inline function dropColumn(columns:Array<String>):Void {
        commands.push(DropColumn(columns));
    }

    public function dropTimestamps():Void {
        dropColumn(["created_at", "updated_at"]);
    }

    public function dropTimestampsTz():Void {
        dropTimestamps();
    }

    public function dropSoftDeletes(column:String = "deleted_at"):Void {
        dropColumn(column);
    }

    public function dropSoftDeletesTz(column:String = "deleted_at"):Void {
        dropSoftDeletes(column);
    }

    public function dropRememberToken():Void {
        dropColumn("remember_token");
    }

    public function dropMorphs(name:String):Void {
        dropIndex(['${name}_type', '${name}_id']);
        dropColumn(['${name}_type', '${name}_id']);
    }

    public function renameColumn(from:String, to:String):Void {
        commands.push(RenameColumn(from, to));
    }

    public function renameIndex(from:String, to:String):Void {
        commands.push(RenameIndex(from, to));
    }

    public overload extern inline function dropIndex(name:String):Void {
        commands.push(DropIndex(name));
    }

    public overload extern inline function dropIndex(columns:Array<String>):Void {
        commands.push(DropIndex(SchemaGrammar.asciiLower('${table}_${columns.join("_")}_index')));
    }

    public overload extern inline function dropUnique(name:String):Void {
        commands.push(DropUnique(name));
    }

    public overload extern inline function dropUnique(columns:Array<String>):Void {
        commands.push(DropUnique(SchemaGrammar.asciiLower('${table}_${columns.join("_")}_unique')));
    }

    public overload extern inline function dropFullText(name:String):Void {
        commands.push(DropFullText(name));
    }

    public overload extern inline function dropFullText(columns:Array<String>):Void {
        commands.push(DropFullText(SchemaGrammar.asciiLower('${table}_${columns.join("_")}_fulltext')));
    }

    public overload extern inline function dropSpatialIndex(name:String):Void {
        commands.push(DropSpatialIndex(name));
    }

    public overload extern inline function dropSpatialIndex(columns:Array<String>):Void {
        commands.push(DropSpatialIndex(SchemaGrammar.asciiLower('${table}_${columns.join("_")}_spatialindex')));
    }

    public function dropPrimary():Void {
        commands.push(DropPrimary);
    }

    public overload extern inline function dropForeign(name:String):Void {
        commands.push(DropForeign(name));
    }

    public overload extern inline function dropForeign(columns:Array<String>):Void {
        commands.push(DropForeign(SchemaGrammar.asciiLower('${table}_${columns.join("_")}_foreign')));
    }
}
