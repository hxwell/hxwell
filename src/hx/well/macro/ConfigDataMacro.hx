package hx.well.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.io.Path;
import haxe.ds.StringMap;
import sys.FileSystem;

using StringTools;

class ConfigDataMacro {
    private static inline var CONFIG_PACKAGE = "hx.well.config";

    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        var configClasses = discoverConfigClasses();
        configClasses.sort((a, b) -> a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1);

        var exprs:Array<Expr> = [];
        var seenFields:StringMap<String> = new StringMap();

        for (clazz in configClasses) {
            var formattedName:String = clazz.name.toLowerCase();
            var fullClass:String = '${clazz.pack.join(".")}.${clazz.name}';

            var existing = seenFields.get(formattedName);
            if (existing != null)
                Context.fatalError('Config class name collision: "${existing}" and "${fullClass}" both map to ConfigData.${formattedName}. Rename one of them.', clazz.pos);
            seenFields.set(formattedName, fullClass);

            var typePath = toTypePath(clazz);

            var newInstanceExpr:Expr = {
                expr: ENew(typePath, []),
                pos: Context.currentPos()
            };

            exprs.push(macro $i{formattedName} = $newInstanceExpr);

            fields.push({
                name: formattedName,
                kind: FVar(TPath(typePath), null),
                pos: Context.currentPos(),
                access: [APublic, AStatic]
            });
        }

        fields.push({
            name: "init",
            kind: FFun({
                args: [],
                expr: macro $b{exprs}
            }),
            pos: Context.currentPos(),
            access: [APublic, AStatic]
        });
        return fields;
    }

    private static function discoverConfigClasses():Array<ClassType> {
        var packageParts = CONFIG_PACKAGE.split(".");
        var seenModules:StringMap<Bool> = new StringMap();
        var classes:Array<ClassType> = [];

        for (classPath in Context.getClassPath()) {
            var directory = Path.join([classPath].concat(packageParts));
            if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
                continue;

            for (entry in FileSystem.readDirectory(directory)) {
                if (!entry.endsWith(".hx"))
                    continue;

                var moduleName = entry.substr(0, entry.length - 3);
                if (moduleName == "ConfigData" || moduleName == "import")
                    continue;

                var modulePath = '${CONFIG_PACKAGE}.${moduleName}';
                if (seenModules.exists(modulePath))
                    continue;
                seenModules.set(modulePath, true);

                for (type in Context.getModule(modulePath)) {
                    switch (type) {
                        case TInst(classRef, _):
                            var clazz = classRef.get();
                            if (!clazz.isInterface && !clazz.isExtern && implementsIConfig(clazz))
                                classes.push(clazz);
                        case _:
                    }
                }
            }
        }

        return classes;
    }

    private static function implementsIConfig(classType:ClassType):Bool {
        var current:Null<ClassType> = classType;
        while (current != null) {
            if (interfacesContainIConfig(current.interfaces))
                return true;
            current = current.superClass != null ? current.superClass.t.get() : null;
        }
        return false;
    }

    private static function interfacesContainIConfig(interfaces:Array<{t:Ref<ClassType>, params:Array<Type>}>):Bool {
        for (entry in interfaces) {
            var interfaceType = entry.t.get();
            if (interfaceType.name == "IConfig" && interfaceType.pack.join(".") == CONFIG_PACKAGE)
                return true;
            if (interfacesContainIConfig(interfaceType.interfaces))
                return true;
        }
        return false;
    }

    private static function toTypePath(clazz:ClassType):TypePath {
        var moduleName = clazz.module.split(".").pop();
        return moduleName == clazz.name
            ? {pack: clazz.pack, name: clazz.name}
            : {pack: clazz.pack, name: moduleName, sub: clazz.name};
    }
}
