package hx.well.config;
import hx.well.middleware.DatabaseMiddleware;
import hx.well.middleware.AbstractMiddleware;
import hx.well.middleware.AuthenticationMiddleware;
import hx.well.middleware.SessionMiddleware;
import hx.well.middleware.SampleMiddleware;

class MiddlewareConfig {
    public static function get():Array<Class<AbstractMiddleware>> {
        return [
            DatabaseMiddleware,
            SessionMiddleware,
            AuthenticationMiddleware,
            SampleMiddleware
        ];
    }
}