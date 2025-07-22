package hx.well.console;

import haxe.Exception;
import sys.FileSystem;
import sys.net.Socket;
import sys.net.Host;
import hx.well.http.driver.socket.SocketInstance;
import hx.well.facades.Config;
using StringTools;

class HostProjectCommand extends AbstractCommand<Bool> {

    private static inline final DEFAULT_HOST = "127.0.0.1";
    private static inline final DEFAULT_PORT = 3000;
    private static inline final MIN_PORT = 0;
    private static inline final MAX_PORT = 65535;

    public function signature():String {
        return "up {path} {host?}";
    }

    public function description():String {
        return "Starts a local web server to serve static files from a specified directory. If the port is in use, it automatically finds the next available one and opens the URL in your browser on startup.";
    }

    public function handle():Bool {
        // 1. Validate the project path
        var path:String = argument("path");
        if (!FileSystem.exists(path)) {
            throw new Exception('The specified path does not exist: ${path}');
        }

        // 2. Get and parse the host argument
        var hostArg:String = argument("host", '${DEFAULT_HOST}:${DEFAULT_PORT}');
        var hostInfo:HostInfo;

        try {
            hostInfo = parseHostAndPort(hostArg);
        } catch (e:Exception) {
            // Re-throw with a more user-friendly context
            throw new Exception('Invalid host argument provided. ${e.message}');
        }

        // 3. Find the first available port, starting from the requested one
        var availablePort = findAvailablePort(hostInfo.host, hostInfo.port);
        var hostIp = hostInfo.host;

        // For display and opening URL, use 127.0.0.1 instead of 0.0.0.0
        var displayIp:String = hostIp == "0.0.0.0" ? DEFAULT_HOST : hostIp;
        trace('Starting server at http://${displayIp}:${availablePort}');

        // 4. Configure and start the server
        Config.set("public.path", path);

        SocketInstance.builder()
        .setHost(hostIp)
        .setPort(availablePort)
        .setOnStart(() -> System.openURL('http://${displayIp}:${availablePort}'))
        .build()
        .driver()
        .start();

        return true;
    }

    /**
     * Parses a string argument that can be a port "port" or a host and port "host:port".
     * @param hostArg The string argument to parse.
     * @return An object containing the host and port.
     * @throws Exception if the format is invalid or the port is out of range.
     */
    private function parseHostAndPort(hostArg:String):HostInfo {
        var hostIp:String = DEFAULT_HOST;
        var portStr:String;

        if (hostArg.contains(":")) {
            var parts = hostArg.split(":");
            if (parts.length != 2 || parts[0] == "" || parts[1] == "") {
                throw new Exception('Invalid format. Use "host:port" or just "port".');
            }
            hostIp = parts[0];
            portStr = parts[1];
        } else {
            // The entire argument is assumed to be the port
            portStr = hostArg;
        }

        var parsedPort = Std.parseInt(portStr);

        if (parsedPort == null) {
            throw new Exception('Port must be a valid number, but received "${portStr}".');
        }

        if (parsedPort < MIN_PORT || parsedPort > MAX_PORT) {
            throw new Exception('Port number must be between ${MIN_PORT} and ${MAX_PORT}. Provided: ${parsedPort}');
        }

        return {host: hostIp, port: parsedPort};
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