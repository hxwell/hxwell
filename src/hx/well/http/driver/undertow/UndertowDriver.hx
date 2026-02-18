package hx.well.http.driver.undertow;

import javax.net.ssl.SSLContext;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.TrustManagerFactory;
import java.security.KeyStore;
import java.io.FileInputStream;
import java.NativeString;

#if java
@:access(hx.well.http.Response)
class UndertowDriver extends AbstractHttpDriver<UndertowDriverConfig> {
    public var undertow:UndertowExtern;

    public function new(config:UndertowDriverConfig) {
        super(config);
    }

    public function start():Void {
        var undertowBuilder = UndertowExtern.builder()
            .setHandler(new UndertowHxwellHandler(this));

        if(config.ssl) {
            var jksPath:String = config.jksPath;
            var keyPassword:NativeString = cast config.keyPassword;
            var storePassword:NativeString = cast config.storePassword;
            if(jksPath == null)
                throw "JKS path must be provided for SSL configuration.";

            if(keyPassword == null)
                throw "Key password must be provided for SSL configuration.";

            if(storePassword == null)
                throw "Store password must be provided for SSL configuration.";

            var keyStore:KeyStore = KeyStore.getInstance("JKS");
            var fis:FileInputStream = new FileInputStream(jksPath);

            keyStore.load(fis, keyPassword.toCharArray());
            fis.close();

            // KeyManager oluştur
            var kmf:KeyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(keyStore, storePassword.toCharArray());

            // TrustManager oluştur (mTLS için opsiyonel)
            var trustManagers = null;
            if (config.trustStorePath != null) {
                var trustStorePassword:NativeString = cast config.trustStorePassword;
                if (trustStorePassword == null)
                    throw "Trust store password must be provided when trust store path is set.";

                var trustStore:KeyStore = KeyStore.getInstance("JKS");
                var trustFis:FileInputStream = new FileInputStream(config.trustStorePath);
                trustStore.load(trustFis, trustStorePassword.toCharArray());
                trustFis.close();

                var tmf:TrustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                tmf.init(trustStore);
                trustManagers = tmf.getTrustManagers();
            }

            // SSL Context başlat
            var sslContext:SSLContext = SSLContext.getInstance("TLS");
            sslContext.init(kmf.getKeyManagers(), trustManagers, null);

            undertowBuilder = undertowBuilder.addHttpsListener(config.port, config.host, sslContext);
        }else{
            undertowBuilder = undertowBuilder.addHttpListener(config.port, config.host);
        }

        for(keyValueIterator in config.serverOption.keyValueIterator()) {
            undertowBuilder.setServerOption(keyValueIterator.key, keyValueIterator.value);
        }

        for(keyValueIterator in config.socketOption.keyValueIterator()) {
            undertowBuilder.setSocketOption(keyValueIterator.key, keyValueIterator.value);
        }

        for(keyValueIterator in config.workerOption.keyValueIterator()) {
            undertowBuilder.setWorkerOption(keyValueIterator.key, keyValueIterator.value);
        }

        undertow = undertowBuilder.build();
        undertow.start();

        // Driver is started, invoke the onStart callback.
        config.onStart();
    }

    public function stop():Void {
        undertow.stop();
    }
}
#end