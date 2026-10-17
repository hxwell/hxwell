package hx.well.database.schema;

import haxe.Exception;
using StringTools;

class SqliteTableDefinition {
    private static var constraintKeywords:Array<String> = ["CONSTRAINT", "PRIMARY", "UNIQUE", "CHECK", "FOREIGN"];

    public var items(default, null):Array<String>;
    public var suffix(default, null):String;

    private function new(items:Array<String>, suffix:String) {
        this.items = items;
        this.suffix = suffix;
    }

    public static function parse(sql:String):SqliteTableDefinition {
        var items:Array<String> = [];
        var depth = 0;
        var itemStart = -1;
        var close = -1;
        var i = 0;
        while (i < sql.length) {
            var code = sql.charCodeAt(i);
            if (code == "'".code || code == '"'.code || code == "`".code) {
                i = skipQuoted(sql, i, code);
            } else if (code == "[".code) {
                i = skipPast(sql, i + 1, "]");
            } else if (code == "-".code && sql.charCodeAt(i + 1) == "-".code) {
                i = skipPast(sql, i, "\n");
            } else if (code == "/".code && sql.charCodeAt(i + 1) == "*".code) {
                i = skipPast(sql, i + 2, "*/");
            } else if (code == "(".code) {
                depth++;
                if (depth == 1)
                    itemStart = i + 1;
                i++;
            } else if (code == ")".code) {
                depth--;
                if (depth == 0) {
                    close = i;
                    break;
                }
                i++;
            } else if (code == ",".code && depth == 1) {
                items.push(sql.substring(itemStart, i));
                itemStart = i + 1;
                i++;
            } else {
                i++;
            }
        }

        if (itemStart == -1 || close == -1)
            throw new Exception('Unable to parse table definition: ${sql}');

        items.push(sql.substring(itemStart, close));
        return new SqliteTableDefinition([for (item in items) item.trim()], sql.substring(close + 1).trim());
    }

    public static function columnName(item:String):Null<String> {
        var identifier = readIdentifier(item, 0);
        if (identifier == null)
            return null;
        if (!identifier.quoted && constraintKeywords.contains(SchemaGrammar.asciiUpper(identifier.name)))
            return null;
        return identifier.name;
    }

    public static function isPrimaryKeyConstraint(item:String):Bool {
        var identifier = readIdentifier(item, 0);
        if (identifier == null || identifier.quoted)
            return false;

        var keyword = SchemaGrammar.asciiUpper(identifier.name);
        if (keyword == "CONSTRAINT") {
            var name = readIdentifier(item, identifier.end);
            if (name == null)
                return false;
            var next = readIdentifier(item, name.end);
            return next != null && !next.quoted && SchemaGrammar.asciiUpper(next.name) == "PRIMARY";
        }
        return keyword == "PRIMARY";
    }

    /** Replace only the name, retaining expressions, collations, sort order and predicates. */
    public static function renameIndex(sql:String, name:String):String {
        var token = readIdentifier(sql, 0);
        if (token == null || SchemaGrammar.asciiUpper(token.name) != "CREATE")
            throw new Exception("Unable to parse index definition.");
        token = readIdentifier(sql, token.end);
        if (token != null && SchemaGrammar.asciiUpper(token.name) == "UNIQUE")
            token = readIdentifier(sql, token.end);
        if (token == null || SchemaGrammar.asciiUpper(token.name) != "INDEX")
            throw new Exception("Unable to parse index definition.");
        token = readIdentifier(sql, token.end);
        if (token != null && !token.quoted && SchemaGrammar.asciiUpper(token.name) == "IF") {
            for (keyword in ["NOT", "EXISTS"]) {
                token = readIdentifier(sql, token.end);
                if (token == null || SchemaGrammar.asciiUpper(token.name) != keyword)
                    throw new Exception("Unable to parse index definition.");
            }
            token = readIdentifier(sql, token.end);
        }
        if (token == null)
            throw new Exception("Unable to parse index definition.");
        return sql.substring(0, token.start) + hx.well.database.query.QueryIdentifier.quote(name) + sql.substring(token.end);
    }

    private static function readIdentifier(text:String, position:Int):Null<{name:String, quoted:Bool, start:Int, end:Int}> {
        var i = position;
        while (i < text.length) {
            if (text.isSpace(i))
                i++;
            else if (text.substr(i, 2) == "--")
                i = skipPast(text, i + 2, "\n");
            else if (text.substr(i, 2) == "/*")
                i = skipPast(text, i + 2, "*/");
            else
                break;
        }
        if (i >= text.length)
            return null;

        var code = text.charCodeAt(i);
        if (code == "'".code || code == '"'.code || code == "`".code) {
            var quote = text.charAt(i);
            var end = skipQuoted(text, i, code);
            return {name: text.substring(i + 1, end - 1).replace(quote + quote, quote), quoted: true, start: i, end: end};
        }
        if (code == "[".code) {
            var end = skipPast(text, i + 1, "]");
            return {name: text.substring(i + 1, end - 1), quoted: true, start: i, end: end};
        }

        var start = i;
        while (i < text.length && isBareIdentifierChar(text.charCodeAt(i)))
            i++;
        return i == start ? null : {name: text.substring(start, i), quoted: false, start: start, end: i};
    }

    private static function isBareIdentifierChar(code:Int):Bool {
        return code > " ".code
            && code != "(".code && code != ")".code && code != ",".code
            && code != "'".code && code != '"'.code && code != "`".code && code != "[".code;
    }

    private static function skipQuoted(text:String, start:Int, quote:Int):Int {
        var i = start + 1;
        while (i < text.length) {
            if (text.charCodeAt(i) == quote) {
                if (text.charCodeAt(i + 1) == quote) {
                    i += 2;
                    continue;
                }
                return i + 1;
            }
            i++;
        }
        return text.length;
    }

    private static function skipPast(text:String, start:Int, terminator:String):Int {
        var end = text.indexOf(terminator, start);
        return end == -1 ? text.length : end + terminator.length;
    }
}
