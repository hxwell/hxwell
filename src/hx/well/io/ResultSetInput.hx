package hx.well.io;
import sys.db.ResultSet;
import haxe.io.Input;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Error;
import haxe.io.Eof;
import hx.well.model.BaseModel;
using StringTools;

class ResultSetInput extends Input {
    private var resultSet:ResultSet;
    private var bufferBytes:BytesInput;
    private var finished:Bool = false;
    private var firstRow:Bool = true;
    private var hasNext:Null<Bool> = null;
    private var visibleFields:Array<String>;
    private var resultSetReplacer:Dynamic->Void;

    public function new(resultSet:ResultSet, ?visibleFields:Array<String>, ?resultSetReplacer:Dynamic->Void) {
        this.resultSet = resultSet;
        this.visibleFields = visibleFields;
        this.resultSetReplacer = resultSetReplacer;
        initializeBuffer();
    }

    private function initializeBuffer():Void {
        hasNext = resultSet.hasNext();
        if (!hasNext) {
            // For empty result set
            bufferBytes = new BytesInput(Bytes.ofString("[]"));
            finished = true;
        }
    }

    override public function readByte():Int {
        return bufferBytes.readByte();
    }

    public override function readBytes(s:Bytes, pos:Int, len:Int):Int {
        if (bufferBytes != null && bufferBytes.length == bufferBytes.position && finished) {
            throw new Eof();
        }

        var k = len;
        var b = #if (js || hl) @:privateAccess s.b #else s.getData() #end;
        if (pos < 0 || len < 0 || pos + len > s.length)
            throw Error.OutsideBounds;

        try {
            while (k > 0) {
                if (bufferBytes == null || bufferBytes.position >= bufferBytes.length) {
                    updateBuffer();
                    if (finished && bufferBytes.position >= bufferBytes.length) {
                        if (k == len) throw new Eof();
                        break;
                    }
                }

                #if neko
                untyped __dollar__sset(b, pos, readByte());
                #elseif php
                b.set(pos, readByte());
                #elseif cpp
                b[pos] = untyped readByte();
                #else
                b[pos] = cast readByte();
                #end
                pos++;
                k--;
            }
        } catch (eof:Eof) {
            if (k == len) throw eof;
        }
        return len - k;
    }

    private function updateBuffer():Void {
        if (finished) return;

        var buffer = new BytesBuffer();

        if (firstRow) {
            buffer.addString("[");
            firstRow = false;
        } else {
            buffer.addString(",");
        }

        var result = resultSet.next();

        if(resultSetReplacer != null)
            resultSetReplacer(result);

        buffer.addString("{");
        var fields = visibleFields ?? Reflect.fields(result);
        for (i in 0...fields.length) {
            var fieldName = fields[i];
            var fieldValue:Dynamic = Reflect.field(result, fieldName);
            buffer.addString('"${escapeString(fieldName)}":');

            if (fieldValue == null) {
                buffer.addString("null");
            } else if (Std.isOfType(fieldValue, String)) {
                buffer.addString('"${escapeString(fieldValue)}"');
            } else if (Std.isOfType(fieldValue, Bool)) {
                buffer.addString(fieldValue ? "true" : "false");
            } else {
                buffer.addString(Std.string(fieldValue));
            }

            if (i < fields.length - 1) buffer.addString(",");
        }
        buffer.addString("}");

        hasNext = resultSet.hasNext();
        if (!hasNext) {
            buffer.addString("]");
            finished = true;
        }

        bufferBytes = new BytesInput(buffer.getBytes());
    }

    private function escapeString(s:String):String {
        return s.replace("\\", "\\\\")
                .replace('"', '\\"')
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    public override function close():Void {
        super.close();
    }
}