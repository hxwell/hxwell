package java.security;

#if haxe5
import java.StdTypes.Char16;
#else
import java.StdTypes.Char16;
#end

extern class KeyStore {
    public static function getInstance(type:String):KeyStore;

    public function load(stream:java.io.InputStream, password:NativeArray<Char16>):Void;
}