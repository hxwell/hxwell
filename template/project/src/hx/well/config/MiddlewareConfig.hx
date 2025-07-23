package hx.well.config;
import hx.well.middleware.DatabaseMiddleware;
import hx.well.middleware.AbstractMiddleware;
import hx.well.middleware.AuthenticationMiddleware;
import hx.well.middleware.SessionMiddleware;
import hx.well.middleware.SampleMiddleware;
import hx.well.middleware.CorsMiddleware;

class MiddlewareConfig {
    public static function get():Array<Class<AbstractMiddleware>> {
        return [
            CorsMiddleware,
            DatabaseMiddleware,
            SessionMiddleware,
            AuthenticationMiddleware,
            SampleMiddleware
        ];
    }
}