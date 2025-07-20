package;
import hx.well.boot.BaseBoot;
import hx.well.route.Route;
import hx.well.server.instance.IInstance;
using hx.well.tools.RouteElementTools;
import hx.well.handler.AbortHandler;
import hx.well.http.driver.socket.SocketInstance;

class Boot extends BaseBoot {
    public function boot():Void {
        Route.get("/abort/{code}")
            .handler(new AbortHandler())
            .where("code", "\\b[1-5][0-9]{2}\\b");
    }

    public function instances():Array<IInstance> {
        return [
            SocketInstance.builder()
                .setHost("0.0.0.0")
                .setPort(1034)
                .build()
        ];
    }
}
