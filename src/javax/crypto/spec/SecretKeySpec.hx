package javax.crypto.spec;
import java.NativeArray;
import java.StdTypes.Int8;

extern class SecretKeySpec implements SecretKey {
    public function new(key:NativeArray<Int8>, algorithm:String);
}
