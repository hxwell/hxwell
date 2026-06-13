package hx.well.http.driver.nodehttp;

#if js
import hx.well.http.driver.AbstractHttpDriver;
import sys.net.Host;
import js.node.Http;
import haxe.Exception;
import js.node.Cluster;

class NodeHttpDriver extends AbstractHttpDriver<NodeHttpDriverConfig> {

    public function new(config:NodeHttpDriverConfig) {
        super(config);
    }

    public function start():Void {
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
                var chunks:Array<js.node.Buffer> = [];
                req.on("data", function(chunk:js.node.Buffer) chunks.push(chunk));
                req.on("end", function() {
                    var context:NodeHttpDriverContext = null;
                    try {
                        var body = js.node.Buffer.concat(chunks).hxToBytes();
                        context = new NodeHttpDriverContext(req, res, body);
                        HttpHandler.process(context);
                    } catch (e:Exception) {
                        tryClose(context);
                    }
                });
                req.on("error", function(_) {});
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