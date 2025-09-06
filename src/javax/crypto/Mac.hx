package javax.crypto;
#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import java.NativeArray;
import java.security.Key;

extern class Mac {
    public static function getInstance(algorithm:String):Mac;
    public function init(key:Key):Void;
    public function doFinal(output:NativeArray<Int8>):NativeArray<Int8>;
}
