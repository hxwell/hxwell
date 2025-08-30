package javax.crypto;
import java.NativeArray;
import java.StdTypes.Int8;
import java.security.Key;

extern class Mac {
    public static function getInstance(algorithm:String):Mac;
    public function init(key:Key):Void;
    public function doFinal(output:NativeArray<Int8>):NativeArray<Int8>;
}
