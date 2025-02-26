package hx.well.tools;

class StringTools {
    public static function replaceOne(s:String, sub:String, by:String):String {
        var index:Int = s.indexOf(sub);
        if(index == -1)
            return s;

        var result = new StringBuf();
        result.addSub(s, 0, index);
        result.add(by);
        result.addSub(s, index + sub.length, s.length - (index + sub.length));
        return result.toString();
    }

    public static function truncateAtNull(value:String):String {
        var result:String = "";
        for (i in 0...value.length) {
            if (value.charCodeAt(i) == 0x00)
                break;
            result += value.charAt(i);
        }
        return result;
    }
}
