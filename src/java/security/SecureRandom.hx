package java.security;

#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import java.NativeArray;

extern class SecureRandom {
    public function new();
    public function nextBytes(bytes:NativeArray<Int8>):Void;
}
