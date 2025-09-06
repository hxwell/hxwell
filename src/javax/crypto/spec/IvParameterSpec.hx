package javax.crypto.spec;
#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import java.NativeArray;
import java.security.spec.AlgorithmParameterSpec;
extern class IvParameterSpec implements AlgorithmParameterSpec {
    public function new(iv:NativeArray<Int8>);
}
