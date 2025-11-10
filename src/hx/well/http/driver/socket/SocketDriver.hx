package hx.well.http.driver.socket;

#if (!php && !js)
import sys.net.Socket;
import sys.net.Host;
import haxe.Exception;
import hx.well.http.HttpHandler;
import hx.concurrent.executor.Executor;
import sys.ssl.Socket as SSLSocket;
import hx.well.http.driver.AbstractHttpDriver;

class SocketDriver extends AbstractHttpDriver<SocketDriverConfig> {
    public var socket:Socket;
    private var executor:Executor;

    public function new(config:SocketDriverConfig) {
        super(config);
        this.socket = config.ssl ? new SSLSocket() : new Socket();
    }

    public function start():Void {
        var host:Host = new Host(config.host);
        var port:Int = config.port;
        var maxConnections:Int = config.maxConnections;
        executor = config.executor();

        socket.setFastSend(true);
        socket.bind(host, port);
        socket.listen(maxConnections);

        // Driver is started, invoke the onStart callback.
        config.onStart();

        while(true) {
            #if !java
            socket.waitForRead();
            #end

            var clientSocket:Socket = socket.accept();
            if(clientSocket == null)
                continue;

            #if !java
            if(clientSocket is SSLSocket)
            {
                var sslClientSocket:SSLSocket = cast clientSocket;
                if(sslClientSocket.verifyCert)
                {
                    try {
                        sslClientSocket.handshake();
                    } catch (e) {
                        try {
                            sslClientSocket.close();
                        } catch (ignored) {}
                        continue;
                    }
                }
            }
            #end

            executor.submit(() -> {
                // Bu try-catch bloğu, thread içindeki hataları yakalar.
                try {
                    var context = new SocketDriverContext(clientSocket);
                    // HttpHandler.process metodu kendi içinde hataları yönetir
                    // ve en sonunda context.close() ile socket'i kapatır.
                    HttpHandler.process(context);
                } catch (e:Exception) {
                    // handler.process içinde yakalanmayan beklenmedik bir hata olursa logla.
                    trace('Unhandled exception in request thread: ${e}');
                    trace(haxe.CallStack.toString(e.stack));

                    // Beklenmedik bir hata durumunda bile socket'i kapatmayı dene.
                    // Normalde handler.process içindeki _cleanup bunu yapmalı,
                    // bu ek bir güvenlik katmanıdır.
                    if (clientSocket != null) {
                        try { clientSocket.close(); } catch (ignored:Dynamic) {}
                    }
                }
            });
        }
    }

    public function stop():Void {
        executor.stop();
        socket.close();
    }
}
#end