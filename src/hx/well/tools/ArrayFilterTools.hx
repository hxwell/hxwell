package hx.well.tools;

class ArrayFilterTools {

    public static function filterLimit<T>(array:Array<T>, limit:Int, f:T->Bool):Array<T> {
        var result:Array<T> = [];
        for (v in array) {
            if (f(v))
                result.push(v);

            if(result.length >= limit)
                break;
        }
        return result;
    }
}
