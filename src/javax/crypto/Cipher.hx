package javax.crypto;
import java.NativeArray;
import java.StdTypes.Int8;
import java.security.spec.AlgorithmParameterSpec;
import java.security.Key;

extern class Cipher {
    public static final ENCRYPT_MODE:Int;
    public static final DECRYPT_MODE:Int;

    public static function getInstance(algorithm:String):Cipher;
    public function init(opmode:Int, key:Key, params:AlgorithmParameterSpec):Void;
    public function doFinal(output:NativeArray<Int8>):NativeArray<Int8>;
}
