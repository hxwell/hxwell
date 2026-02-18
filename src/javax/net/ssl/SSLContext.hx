package javax.net.ssl;

import javax.net.ssl.KeyManager;
import javax.net.ssl.TrustManager;
import java.security.SecureRandom;
import java.NativeArray;

@:native("javax.net.ssl.SSLContext")
extern class SSLContext {
    static function getDefault():SSLContext;
    static function getInstance(protocol:String):SSLContext;

    @:native("init")
    @:throws("java.security.KeyManagementException")
    function init(km:NativeArray<KeyManager>, tm:NativeArray<TrustManager>, random:SecureRandom):Void;
}