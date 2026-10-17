package hx.well.database.schema;

class ForeignKeyDefinition {
    public var columns(default, null):Array<String>;
    public var referencedColumns(default, null):Array<String> = ["id"];
    public var referencedTable(default, null):Null<String>;
    public var onDeleteAction(default, null):Null<String>;
    public var onUpdateAction(default, null):Null<String>;
    public var name(default, null):Null<String>;

    public function new(columns:Array<String>, ?name:String) {
        this.columns = columns;
        this.name = name;
    }

    public overload extern inline function references(column:String):ForeignKeyDefinition {
        return references([column]);
    }

    public overload extern inline function references(columns:Array<String>):ForeignKeyDefinition {
        this.referencedColumns = columns;
        return this;
    }

    public function on(table:String):ForeignKeyDefinition {
        this.referencedTable = table;
        return this;
    }

    public function onDelete(action:String):ForeignKeyDefinition {
        this.onDeleteAction = action;
        return this;
    }

    public function onUpdate(action:String):ForeignKeyDefinition {
        this.onUpdateAction = action;
        return this;
    }

    public function cascadeOnDelete():ForeignKeyDefinition {
        return onDelete("cascade");
    }

    public function restrictOnDelete():ForeignKeyDefinition {
        return onDelete("restrict");
    }

    public function nullOnDelete():ForeignKeyDefinition {
        return onDelete("set null");
    }

    public function cascadeOnUpdate():ForeignKeyDefinition {
        return onUpdate("cascade");
    }
}
