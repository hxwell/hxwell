package hx.well.utils;
import haxe.Exception;
import haxe.CallStack;
import haxe.Resource;
import haxe.io.Path;

// Typedef
typedef StackFrame = {
    var file:String;
    var method:String;
    var line:Int;
    var startLine:Int;
    var endLine:Int;
    @:optional var code:Array<CodeLine>;
    @:optional var highlighted:Bool;
}

typedef CodeLine = {
    var line:Int;
    var content:String;
    var isError:Bool;
}

typedef StackFrames = Array<StackFrame>;

class StackFrameParser {
    public static function fromException(e:Exception):StackFrames {
        var items = e.stack;
        var frames:Array<StackFrame> = [];

        for (i in 0...items.length) {
            var item:StackItem = items[i];
            var frame:Null<StackFrame> = convertStackItem(item);

            if (frame != null && frame.line != -1)
            {
                #if include_source
                extractSource(frame);
                #end
                frames.push(frame);
            }
        }

        return frames;
    }

    static function convertStackItem(item:StackItem):Null<StackFrame> {
        return switch (item) {
            case FilePos(s, file, line, _):
                var methodName = extractMethodName(s);
                {
                    file: Path.normalize(file),
                    method: methodName,
                    line: line,
                    startLine: line,
                    endLine: line
                };
            case Method(classname, method):
                {
                    file: classname != null ? classname : "unknown",
                    method: method,
                    line: 0,
                    startLine: 0,
                    endLine: 0
                };
            case Module(m):
                {
                    file: m,
                    method: "module",
                    line: 0,
                    startLine: 0,
                    endLine: 0
                };
            case LocalFunction(v):
                {
                    file: "local",
                    method: 'local#' + (v != null ? v : 0),
                    line: 0,
                    startLine: 0,
                    endLine: 0
                };
            case CFunction:
                {
                    file: "native",
                    method: "c-function",
                    line: 0,
                    startLine: 0,
                    endLine: 0
                };
        }
    }

    #if include_source
    static function extractSource(item:StackFrame):Void {
        var file:Null<String> = Path.normalize(item.file);
        trace('source/${file}');
        var sourceCode = Resource.getString('source/${file}');
        if(sourceCode == null)
            return;

        var sourceLines = sourceCode.split('\n');

        var fileStartLine:Int = cast Math.max(item.startLine - 18, 0);
        var fileEndLine:Int = cast Math.min(item.endLine + 2, sourceLines.length - 1);

        item.code = [];

        for(i in fileStartLine...fileEndLine) {
            var lineContent = sourceLines[i];
            item.code.push({
                line: i + 1,
                content: lineContent,
                isError: i + 1 == item.line
            });
        }
    }
    #end

    static function extractMethodName(item:Null<StackItem>):String {
        return switch (item) {
            case Method(c, m): c != null ? '$c.$m' : m;
            case FilePos(inner, _, _, _): extractMethodName(inner);
            case LocalFunction(n): 'local#' + (n != null ? n : 0);
            case Module(m): m;
            case CFunction: 'c-function';
            case null: "unknown";
        }
    }
}