package hx.well.http.driver.nodehttp;

#if js
import hx.well.http.driver.AbstractHttpDriver;
import sys.net.Host;
import js.node.Http;
import haxe.CallStack.CallStack.toString;
import haxe.Exception;
import hx.well.http.driver.undertow.UndertowDriverContext;
import haxe.CallStack;
import js.node.Cluster;

class NodeHttpDriver extends AbstractHttpDriver<NodeHttpDriverConfig> {

    public function new(config:NodeHttpDriverConfig) {
        super(config);
    }

    public function start():Void {
        trace("start");
        var host:Host = new Host(config.host);
        var port:Int = config.port;

        // Driver is started, invoke the onStart callback.
        config.onStart();

        var cluster = Cluster.instance;

        if (cluster.isMaster) {
            cluster.schedulingPolicy = ClusterSchedulingPolicy.SCHED_RR;

            for (i in 0...config.poolSize) {
                cluster.fork();
            }

            cluster.on('exit', (worker, code, signal) -> {
                // TODO: Log why worker exited.
                cluster.fork();
            });
        } else if (cluster.isWorker) {
            var server = Http.createServer((req, res) -> {
                var context:NodeHttpDriverContext = null;
                try {
                    context = new NodeHttpDriverContext(req, res);
                    HttpHandler.process(context);
                } catch (e:Exception) {
                    tryClose(context);
                }
            });

            // Server listens on port 3000
            server.listen({host: host.toString(), port: port}, () -> {
                trace('Server running at http://localhost:${port}/');
            });
        }
    }

    private function tryClose(context:NodeHttpDriverContext):Void {
        try {
            context?.close();
        } catch (e:Exception) {

        }
    }

    public function stop():Void {

    }
}
#end