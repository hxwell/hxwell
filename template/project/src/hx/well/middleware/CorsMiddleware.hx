package hx.well.middleware;
class CorsMiddleware extends AbstractCorsMiddleware {
    public function allowedOrigins():Array<String> {
        return ["*"];
    }

    public function allowedMethods():Array<String> {
        return ["GET", "POST", "PUT", "DELETE", "OPTIONS"];
    }

    public function allowedHeaders():Array<String> {
        return [];
    }

    public function allowCredentials():Bool {
        return false;
    }

    public function maxAge():Int {
        return 3600;
    }

    public function exposedHeaders():Array<String> {
        return [];
    }
}