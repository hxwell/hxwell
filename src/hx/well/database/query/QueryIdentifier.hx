package hx.well.database.query;

import haxe.Exception;

class QueryIdentifier {
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
