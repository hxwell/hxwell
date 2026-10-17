package hx.well.database.schema;

class ColumnDefinition {
    public var name(default, null):String;
    public var type(default, null):ColumnType;
    public var length:Null<Int>;
    public var total:Null<Int>;
    public var places:Null<Int>;
    public var precision:Null<Int>;
    public var allowed:Null<Array<String>>;
    public var subtype:Null<String>;
    public var srid:Null<Int>;
    public var isNullable:Bool = false;
    public var hasDefault:Bool = false;
    public var defaultVal:Dynamic;
    public var isUnsigned:Bool = false;
    public var isAutoIncrement:Bool = false;
    public var isPrimary:Bool = false;
    public var isUnique:Bool = false;
    public var hasIndex:Bool = false;
    public var isFullText:Bool = false;
    public var isSpatialIndex:Bool = false;
    public var uniqueName:Null<String>;
    public var indexName:Null<String>;
    public var fullTextName:Null<String>;
    public var spatialIndexName:Null<String>;
    public var usesCurrent:Bool = false;
    public var usesCurrentOnUpdate:Bool = false;
    public var commentText:Null<String>;
    public var afterColumn:Null<String>;
    public var isFirst:Bool = false;
    public var charsetName:Null<String>;
    public var collationName:Null<String>;
    public var storedAsExpr:Null<String>;
    public var virtualAsExpr:Null<String>;
    public var isChange:Bool = false;

    public function new(name:String, type:ColumnType) {
        this.name = name;
        this.type = type;
    }

    public function nullable(value:Bool = true):ColumnDefinition {
        isNullable = value;
        return this;
    }

    public function defaultValue(value:Dynamic):ColumnDefinition {
        hasDefault = true;
        defaultVal = value;
        return this;
    }

    public function unsigned():ColumnDefinition {
        isUnsigned = true;
        return this;
    }

    public function autoIncrement():ColumnDefinition {
        isAutoIncrement = true;
        return this;
    }

    public function primary():ColumnDefinition {
        isPrimary = true;
        return this;
    }

    public function unique(?name:String):ColumnDefinition {
        isUnique = true;
        uniqueName = name;
        return this;
    }

    public function index(?name:String):ColumnDefinition {
        hasIndex = true;
        indexName = name;
        return this;
    }

    public function fullText(?name:String):ColumnDefinition {
        isFullText = true;
        fullTextName = name;
        return this;
    }

    public function spatialIndex(?name:String):ColumnDefinition {
        isSpatialIndex = true;
        spatialIndexName = name;
        return this;
    }

    public function useCurrent():ColumnDefinition {
        usesCurrent = true;
        return this;
    }

    public function useCurrentOnUpdate():ColumnDefinition {
        usesCurrentOnUpdate = true;
        return this;
    }

    public function comment(text:String):ColumnDefinition {
        commentText = text;
        return this;
    }

    public function after(column:String):ColumnDefinition {
        afterColumn = column;
        return this;
    }

    public function first():ColumnDefinition {
        isFirst = true;
        return this;
    }

    public function charset(charset:String):ColumnDefinition {
        charsetName = charset;
        return this;
    }

    public function collation(collation:String):ColumnDefinition {
        collationName = collation;
        return this;
    }

    public function storedAs(expression:String):ColumnDefinition {
        storedAsExpr = expression;
        return this;
    }

    public function virtualAs(expression:String):ColumnDefinition {
        virtualAsExpr = expression;
        return this;
    }

    public function change():ColumnDefinition {
        isChange = true;
        return this;
    }
}
