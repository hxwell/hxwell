package hx.well.database.schema;

enum SchemaCommand {
    AddPrimary(columns:Array<String>, name:Null<String>);
    AddUnique(columns:Array<String>, name:Null<String>);
    AddIndex(columns:Array<String>, name:Null<String>);
    AddFullText(columns:Array<String>, name:Null<String>);
    AddSpatialIndex(columns:Array<String>, name:Null<String>);
    AddForeign(foreign:ForeignKeyDefinition);
    DropColumn(columns:Array<String>);
    RenameColumn(from:String, to:String);
    RenameIndex(from:String, to:String);
    DropIndex(name:String);
    DropUnique(name:String);
    DropFullText(name:String);
    DropSpatialIndex(name:String);
    DropPrimary;
    DropForeign(name:String);
}
