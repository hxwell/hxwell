package hx.well.middleware;
class CorsMiddleware extends AbstractCorsMiddleware {
    public function allowedOrigins():Array<String> {
        return ["*"];
    }
}