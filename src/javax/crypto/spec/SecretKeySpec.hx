package javax.crypto.spec;
#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import java.NativeArray;

extern class SecretKeySpec implements SecretKey {
    public function new(key:NativeArray<Int8>, algorithm:String);
}
