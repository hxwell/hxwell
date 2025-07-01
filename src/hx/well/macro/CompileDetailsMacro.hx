package hx.well.macro;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.Exception;
import sys.io.Process;
using hx.well.tools.FieldTools;

class CompileDetailsMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        // Defines
        var definesMap:Array<Expr> = [];
        for(key in Context.getDefines().keys()) {
            var value = Context.getDefines().get(key);
            definesMap.push(macro $v{key} => $v{value});
        }

        var definesField = fields.getFieldOrFail("defines");
        definesField.kind = FieldType.FVar(macro:Map<String, String>, macro $a{definesMap});

        // Operating System
        var operatingSystem = Sys.systemName();
        var operatingSystemField = fields.getFieldOrFail("operatingSystem");
        operatingSystemField.kind = FieldType.FVar(macro:String, macro $v{operatingSystem});

        // Date
        var date:String = Date.now().toString();
        var dateField = fields.getFieldOrFail("date");
        dateField.kind = FieldType.FVar(macro:String, macro $v{date});

        // Git Commit
        var gitCommit:String = "not available";

        try {
            var process = new Process("git", ["rev-parse", "--short", "HEAD"]);
            gitCommit = process.stdout.readLine();
        } catch (e:Exception) {

        }

        var gitCommitField = fields.getFieldOrFail("gitCommit");
        gitCommitField.kind = FieldType.FVar(macro:String, macro $v{gitCommit});

        return fields;
    }
}
