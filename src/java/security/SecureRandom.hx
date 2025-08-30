package java.security;

import java.NativeArray;
import java.StdTypes.Int8;

extern class SecureRandom {
    public function new();
    public function nextBytes(bytes:NativeArray<Int8>):Void;
}
