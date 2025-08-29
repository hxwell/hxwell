package hx.well.macro;

import haxe.macro.Expr.Field;
import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;

class ModelMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        var primaryField:Null<MetaFieldData> = findFieldMetaKey(":primary", fields);
        if(primaryField == null)
        {
            throw "@:primary required.";
        }

        var table = findClassMetaKey(":table");
        if(table != null) {
            if(table.metadataEntry.params.length != 1) {
                throw "@:table requires 1 parameter.";
            }
            trace(table.metadataEntry.params[0]);
        }else{
            throw '@:table("tableName") paramter is required on model.';
        }

        var connection = findClassMetaKey(":connection");
        if(connection != null) {
            if(connection.metadataEntry.params.length != 1) {
                throw "@:table requires at least 1 parameter.";
            }
        }

        var constructorField = fields.find(field -> field.name == "new");
        switch (constructorField.kind) {
            case FFun(f):
                var exprs:Array<Expr> = [];

                exprs.push(macro {
                    super();

                    setTable(${table.metadataEntry.params[0]});
                });

                if(connection != null) {
                    exprs.push(macro {
                        setConnection(${connection.metadataEntry.params[0]});
                    });
                }

                if(primaryField != null) {
                    exprs.push(macro {
                        setPrimary($v{primaryField.field.name});
                    });
                }

                f.expr = macro $b{exprs};
            default:
        }

        var databaseFields = filterFieldMetaKey(":field", fields).map(metaFieldData -> metaFieldData.field.name);

        var getDatabaseFieldsFunction:haxe.macro.Function = cast {
            args: [],
            expr: macro {
                return $v{databaseFields}
            },
            ret: macro :Array<String>
        };

        var getDatabaseFields = {
            name: "getDatabaseFields",
            pos: Context.currentPos(),
            kind: FFun(getDatabaseFieldsFunction),
            access: [APublic, AOverride],
            doc: null,
            meta: [{
                name: ":keep",
                pos: Context.currentPos()
            }],
        }
        fields.push(getDatabaseFields);

        var visibleDatabaseFields = filterFieldMetaKey(":visible", fields).map(metaFieldData -> metaFieldData.field.name);
        var getVisibleDatabaseFieldsFunction:haxe.macro.Function = cast {
            args: [],
            expr: macro {
                return $v{visibleDatabaseFields}
            },
            ret: macro :Array<String>
        };
        var getVisibleDatabaseFields = {
            name: "getVisibleDatabaseFields",
            pos: Context.currentPos(),
            kind: FFun(getVisibleDatabaseFieldsFunction),
            access: [APublic, AOverride],
            doc: null,
            meta: [{
                name: ":keep",
                pos: Context.currentPos()
            }],
        }
        fields.push(getVisibleDatabaseFields);

        // Find instance static field, if not available, throw error, if available initialize this with current class
        var instanceField = fields.find(field -> field.name == "instance" && field.access.contains(AStatic));
        if(instanceField == null) {
            throw "Static 'instance' field is required.";
        }

        var currentClass = Context.getLocalClass().get();
        var classTypePath = {
            pack: currentClass.pack,
            name: currentClass.name,
            params: []
        };

        switch (instanceField.kind) {
            case FVar(t, e):
                // Create new instance expression: new ClassName()
                var newInstanceExpr = macro new $classTypePath();

                // Update the field to initialize with the new instance
                instanceField.kind = FVar(t, newInstanceExpr);
            default:
                throw "Instance field must be a variable.";
        }

        return fields;
    }

    private static function filterFieldMetaKey(key:String, fields:Array<Field>):Array<MetaFieldData> {
        var metaFieldDataArray:Array<MetaFieldData> = [];

        for(field in fields) {
            var metadataEntry:Null<MetadataEntry> = findMetaKey(key, field.meta);
            if(metadataEntry != null)
            {
                metaFieldDataArray.push({
                    field: field,
                    metadataEntry: metadataEntry
                });
            }
        }

        return metaFieldDataArray;
    }

    private static function findFieldMetaKey(key:String, fields:Array<Field>):Null<MetaFieldData> {
        for(field in fields) {
            var metadataEntry:Null<MetadataEntry> = findMetaKey(key, field.meta);
            if(metadataEntry != null)
            {
                return {
                    field: field,
                    metadataEntry: metadataEntry
                }
            }
        }

        return null;
    }

    private static function findClassMetaKey(key:String) {
        var metadataEntry:Null<MetadataEntry> = findMetaKey(key, Context.getLocalClass().get().meta.get());
        if(metadataEntry != null)
        {
            return {
                metadataEntry: metadataEntry
            }
        }

        return null;
    }

    private static function findMetaKey(key:String, metadataEntries:Metadata):Null<MetadataEntry> {
        return metadataEntries.find(metadataEntry -> metadataEntry.name == key);
    }
}


//
typedef MetaFieldData = {
    field: Field,
    metadataEntry:MetadataEntry
}