package hx.well.database.schema;

using StringTools;

class ForeignIdColumnDefinition extends ColumnDefinition {
    private var blueprint:Blueprint;

    public function new(blueprint:Blueprint, name:String, type:ColumnType) {
        super(name, type);
        this.blueprint = blueprint;
    }

    public function constrained(?table:String, column:String = "id", ?indexName:String):ForeignKeyDefinition {
        if (table == null)
            table = guessTable(column);

        return blueprint.foreign(name, indexName).references(column).on(table);
    }

    public override function nullable(value:Bool = true):ForeignIdColumnDefinition {
        super.nullable(value);
        return this;
    }

    public override function defaultValue(value:Dynamic):ForeignIdColumnDefinition {
        super.defaultValue(value);
        return this;
    }

    public override function unsigned():ForeignIdColumnDefinition {
        super.unsigned();
        return this;
    }

    public override function autoIncrement():ForeignIdColumnDefinition {
        super.autoIncrement();
        return this;
    }

    public override function primary():ForeignIdColumnDefinition {
        super.primary();
        return this;
    }

    public override function unique(?name:String):ForeignIdColumnDefinition {
        super.unique(name);
        return this;
    }

    public override function index(?name:String):ForeignIdColumnDefinition {
        super.index(name);
        return this;
    }

    public override function fullText(?name:String):ForeignIdColumnDefinition {
        super.fullText(name);
        return this;
    }

    public override function spatialIndex(?name:String):ForeignIdColumnDefinition {
        super.spatialIndex(name);
        return this;
    }

    public override function useCurrent():ForeignIdColumnDefinition {
        super.useCurrent();
        return this;
    }

    public override function useCurrentOnUpdate():ForeignIdColumnDefinition {
        super.useCurrentOnUpdate();
        return this;
    }

    public override function comment(text:String):ForeignIdColumnDefinition {
        super.comment(text);
        return this;
    }

    public override function after(column:String):ForeignIdColumnDefinition {
        super.after(column);
        return this;
    }

    public override function first():ForeignIdColumnDefinition {
        super.first();
        return this;
    }

    public override function charset(charset:String):ForeignIdColumnDefinition {
        super.charset(charset);
        return this;
    }

    public override function collation(collation:String):ForeignIdColumnDefinition {
        super.collation(collation);
        return this;
    }

    public override function storedAs(expression:String):ForeignIdColumnDefinition {
        super.storedAs(expression);
        return this;
    }

    public override function virtualAs(expression:String):ForeignIdColumnDefinition {
        super.virtualAs(expression);
        return this;
    }

    public override function change():ForeignIdColumnDefinition {
        super.change();
        return this;
    }

    private function guessTable(column:String):String {
        var suffix = name.lastIndexOf('_${column}');
        var base = suffix == -1 ? name : name.substring(0, suffix);
        return '${base}s';
    }
}
