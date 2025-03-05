package hx.well.facades;

class Validator {
    private static var validators:Map<String, String->Dynamic->Array<Dynamic>->Bool> = new Map();

    public static function extend(name:String, callback:String->Dynamic->Array<Dynamic>->Bool):Void {
        validators.set(name, callback);
    }

    public static function validate(name:String, attribute:String, value:Dynamic, params:Array<Dynamic>):Bool {
        if(!validators.exists(name))
            throw '${name} validator does not exists!';

        var validator = validators.get(name);
        return validator(attribute, value, params);
    }
}