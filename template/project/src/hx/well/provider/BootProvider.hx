package hx.well.provider;
import hx.well.route.Route;
import hx.well.handler.AbortHandler;
class BootProvider extends AbstractProvider {
    public function boot():Void {
        Route.get("/abort/{code}")
            .handler(new AbortHandler())
            .where("code", "\\b[1-5][0-9]{2}\\b");
    }
}
