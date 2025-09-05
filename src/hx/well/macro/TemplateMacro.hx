package hx.well.macro;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import haxe.io.Path;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import haxe.Template;
import haxe.macro.Expr;
using StringTools;
using StringTools;
using hx.well.tools.FieldTools;

class TemplateMacro {
    private static var templateKeys:Array<String> = [];

    public static function build():Array<Field> {

        // haxelib libpath
        var process = new Process("haxelib", ["libpath", "hxwell"]);
        createTemplateData('${process.stdout.readLine()}/resource/template');

        // Program Path, Dominant
        createTemplateData('${Sys.getCwd()}/template');

        var fields = Context.getBuildFields();

        var dataField:Field = fields.getFieldOrFail("data");

        // Create expressions for each template to populate the StringMap
        var dataExprs:Array<Expr> = [];


        for(templateKey in templateKeys) {
            var templateExpr:Expr = macro new Template(haxe.Resource.getString('template.' + $v{templateKey}));
            dataExprs.push(macro $v{templateKey} => $templateExpr);
        }

        // Add create exprs into data field.
        dataField.kind = FieldType.FVar(macro:Map<String, Template>, macro $a{dataExprs});

        return fields;
    }

    private static function createTemplateData(path:String, rootPath:String = null):Void {
        if(rootPath == null)
            rootPath = path;

        // Recursively add resources from the specified path
        path = Path.normalize(path);
        rootPath = Path.normalize(rootPath);
        var files = FileSystem.readDirectory(path);
        for (file in files) {
            var fullPath = path + "/" + file;
            if (FileSystem.isDirectory(fullPath)) {
                createTemplateData(fullPath, rootPath);
            } else {
                if(!fullPath.endsWith(".mtt.html"))
                {
                    trace(fullPath);
                    continue;
                }

                // Add the file as a resource
                var simplePath = fullPath.substring(rootPath.length + 1).replace("/", ".");
                simplePath = simplePath.substring(0, simplePath.length - ".mtt.html".length);

                if(!templateKeys.contains(simplePath))
                    templateKeys.push(simplePath);
                haxe.macro.Context.addResource('template.${simplePath}', File.getBytes(fullPath));
            }
        }
    }
}
