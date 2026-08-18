package hx.well.internal;

#if java
#if haxe5
import jvm.Int8;
#else
import java.StdTypes.Int8;
#end
import java.NativeArray;

@:native("java.security.MessageDigest")
extern class MessageDigestExtern {
    public static function isEqual(digestA:NativeArray<Int8>, digestB:NativeArray<Int8>):Bool;
}
#end
