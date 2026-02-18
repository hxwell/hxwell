package javax.net.ssl;

#if haxe5
import java.StdTypes.Char16;
#else
import java.StdTypes.Char16;
#end
import java.security.KeyStore;
import java.NativeArray;

extern class TrustManagerFactory {
    public static function getDefaultAlgorithm():String;

    public static function getInstance(algorithm:String):TrustManagerFactory;

    public function init(ks:KeyStore):Void;

    public function getTrustManagers():NativeArray<TrustManager>;
}