package hx.well.database.query;

import haxe.Exception;

class QueryIdentifier {
    /** SELECT accepts identifiers, qualified wildcards and explicit AS aliases. */
    public static function projection(value:String):String {
        if(value == null)
            throw new Exception("Select column must not be null");
        var alias = ~/^([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*) +[aA][sS] +([A-Za-z_][A-Za-z0-9_]*)$/;
        if(alias.match(value))
            return reference(alias.matched(1)) + " AS " + alias.matched(2);
        if(value == "*")
            return value;
        if(StringTools.endsWith(value, ".*"))
            return reference(value.substr(0, value.length - 2)) + ".*";
        return reference(value);
    }

    public static function reference(identifier:String):String {
        if(identifier == null)
            throw new Exception("Column identifier must not be null");
        for(part in identifier.split(".")) {
            if(!isValid(part))
                throw new Exception('Invalid column identifier: ${identifier}');
        }
        return identifier;
    }

    public static function comparisonOperator(value:String):String {
        var normalized = keyword(value);
        if(!["=", "!=", "<>", "<", "<=", ">", ">=", "<=>", "LIKE", "NOT LIKE", "IS", "IS NOT", "REGEXP", "NOT REGEXP", "RLIKE"].contains(normalized))
            throw new Exception('Invalid comparison operator: ${value}');
        return normalized;
    }

    public static function keyword(value:String):String {
        // SQL keywords are ASCII; JVM case conversion depends on the host locale.
        if(value == null)
            return "";
        var result = new StringBuf();
        var trimmed = StringTools.trim(value);
        for(i in 0...trimmed.length) {
            var code = trimmed.charCodeAt(i);
            result.addChar(code >= 'a'.code && code <= 'z'.code ? code - 32 : code);
        }
        return result.toString();
    }

    public static function quote(identifier:String):String {
        if(!isValid(identifier))
            throw new Exception('Invalid column identifier: ${identifier}');

        return '`${identifier}`';
    }

    public static function isValid(identifier:String):Bool {
        if(identifier == null || identifier.length == 0)
            return false;

        for(i in 0...identifier.length) {
            var code = identifier.charCodeAt(i);

            if((code >= 'a'.code && code <= 'z'.code) || (code >= 'A'.code && code <= 'Z'.code) || code == '_'.code)
                continue;

            if(i > 0 && code >= '0'.code && code <= '9'.code)
                continue;

            return false;
        }

        return true;
    }
}
