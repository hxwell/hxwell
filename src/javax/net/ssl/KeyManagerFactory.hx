package javax.net.ssl;

#if haxe5
import java.StdTypes.Char16;
#else
import java.StdTypes.Char16;
#end
import java.security.KeyStore;
import java.NativeArray;

extern class KeyManagerFactory implements KeyManager {
    public static function getDefaultAlgorithm():String;
    public static function getInstance(algorithm:String):KeyManagerFactory;
    public function init(ks:KeyStore, password:NativeArray<Char16>):Void;
    public function getKeyManagers():NativeArray<KeyManager>;
}