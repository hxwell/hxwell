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
            var contentLengthLimit:Int = maxContentLength();

            var server = Http.createServer((req, res) -> {
                var chunks:Array<js.node.Buffer> = [];
                var receivedLength:Int = 0;
                var rejected:Bool = false;

                var declaredLength = Std.parseInt(req.headers.get("content-length"));
                if(declaredLength != null && declaredLength > contentLengthLimit) {
                    rejected = true;
                    rejectTooLarge(req, res);
                }

                req.on("data", function(chunk:js.node.Buffer) {
                    if(rejected)
                        return;

                    receivedLength += chunk.length;
                    if(receivedLength > contentLengthLimit) {
                        rejected = true;
                        chunks = [];
                        rejectTooLarge(req, res);
                        return;
                    }

                    chunks.push(chunk);
                });
                req.on("end", function() {
                    if(rejected)
                        return;

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

    private function maxContentLength():Int {
        var configured:Null<Int> = hx.well.facades.Config.get("http.max_content_length");
        if(configured == null || configured <= 0)
            return 1048576;

        return configured;
    }

    private function rejectTooLarge(req:js.node.http.IncomingMessage, res:js.node.http.ServerResponse):Void {
        try {
            res.once("finish", function() {
                try {
                    req.destroy();
                } catch (e:Exception) {

                }
            });

            res.statusCode = 413;
            res.setHeader("Connection", "close");
            res.end();
        } catch (e:Exception) {
            try {
                req.destroy();
            } catch (e:Exception) {

            }
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