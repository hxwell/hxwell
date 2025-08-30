package javax.crypto.spec;
import java.NativeArray;
import java.security.spec.AlgorithmParameterSpec;
import java.StdTypes.Int8;

extern class IvParameterSpec implements AlgorithmParameterSpec {
    public function new(iv:NativeArray<Int8>);
}
