package hx.well.console;

import haxe.io.Path;
import haxe.Exception;
import sys.FileSystem;
import sys.net.Socket;
import sys.net.Host;
import hx.well.http.driver.socket.SocketInstance;
import hx.well.facades.Config;
using StringTools;

class HostProjectCommand extends AbstractCommand<Bool> {

    private static inline final DEFAULT_HOST = "127.0.0.1";
    private static inline final DEFAULT_PORT = "3000";
    private static inline final MIN_PORT = 0;
    private static inline final MAX_PORT = 65535;

    public function signature():String {
        return "up {path}";
    }

    public function description():String {
        return "Starts a local web server to serve static files from a specified directory. If the port is in use, it automatically finds the next available one and opens the URL in your browser on startup.";
    }

    public function handle():Bool {
        // 1. Validate the project path
        var path:String = argument("path");
        if (!FileSystem.exists(path)) {
			// Maybe it's a relative path
			var relativePath:String = Path.join([Sys.args().pop(), path]);
			if (!FileSystem.exists(relativePath))
				throw new Exception('The specified path does not exist: ${path}');
			else
				path = relativePath;
		}

        // 2. Get and parse the host argument
        var host:String = getOption("host", DEFAULT_HOST);
        var port:Int = Std.parseInt(getOption("port", DEFAULT_PORT));

        // 3. Find the first available port, starting from the requested one
        var availablePort = findAvailablePort(host, port);

        // For display and opening URL, use 127.0.0.1 instead of 0.0.0.0
        var displayIp:String = host == "0.0.0.0" ? DEFAULT_HOST : host;
        trace('Starting server at http://${displayIp}:${availablePort}');

        // 4. Configure and start the server
        Config.set("public.path", path);

        SocketInstance.builder()
            .setHost(host)
            .setPort(availablePort)
            .setPoolSize(Std.parseInt(getOption("poolSize", "6")))
            .setOnStart(() -> System.openURL('http://${displayIp}:${availablePort}'))
            .build()
            .driver()
            .start();

        return true;
    }

    /**
     * Finds an available network port by trying to bind to the initialPort,
     * and incrementing if it's already in use.
     * @param host The host IP to check against.
     * @param initialPort The first port to try.
     * @return The first available port found.
     * @throws Exception if no available port is found up to MAX_PORT.
     */
    private function findAvailablePort(host:String, port:Int):Int {
        var initialPort = port;
        while (port <= MAX_PORT) {
            var socket = new Socket();
            try {
                // Try to bind to the current port
                socket.bind(new Host(host), port);
                // If successful, the port is available. Close the socket immediately
                // to free it up for the actual server, and return the port number.
                socket.close();
                return port;
            } catch (e:Exception) {
                // This port is likely in use, let's inform the user and try the next one.
                trace('Port ${port} is in use, trying the next one...');
                port++;
            }
            socket.close();
        }

        // If the loop completes, no port was found.
        throw new Exception('No available port found for host ${host} starting from port ${initialPort}.');
    }
}

typedef HostInfo = {
    host:String,
    port:Int
};