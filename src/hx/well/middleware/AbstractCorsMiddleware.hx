package hx.well.middleware;
import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseBuilder;


abstract class AbstractCorsMiddleware extends AbstractMiddleware
{
    /**
     * The list of allowed origins for CORS requests.
     * Example: `["https://example.com", "https://another-domain.com"]`.
     * Use `["*"]` to allow all origins, but this is not allowed if `allowCredentials` is `true`.
     */
    public abstract function allowedOrigins():Array<String>;

    /**
     * The list of allowed HTTP methods.
     * Example: `["GET", "POST", "PUT", "DELETE"]`.
     */
    public abstract function allowedMethods():Array<String>;

    /**
     * The list of allowed HTTP headers for preflight requests.
     * Example: `["Content-Type", "Authorization"]`.
     */
    public abstract function allowedHeaders():Array<String>;

    /**
     * Indicates whether the response to the request can be exposed when the credentials flag is true.
     * If `true`, the `Access-Control-Allow-Origin` header cannot be `"*"`.
     */
    public abstract function allowCredentials():Bool;

    /**
     * The value of the `Access-Control-Max-Age` header in seconds.
     * Specifies how long the results of a preflight request can be cached.
     */
    public abstract function maxAge():Int;


    /**
     * The list of headers that can be exposed as part of the response by listing their names.
     * Example: `["Content-Length"]`.
     */
    public abstract function exposedHeaders():Array<String>;

    /**
     * The main handler function for the middleware.
     * It processes the request for CORS headers and either terminates the response (for preflight requests)
     * or passes control to the next middleware.
     */
    public function handle(request:Request, next:Request->Null<Response>):Null<Response> {
        if(request.method != "OPTIONS")
            return next(request);

        var origin = request.header('Origin');
        if (origin == null) {
            return next(request);
        }

        var allowedOrigins = allowedOrigins();
        var allowedMethods = allowedMethods();
        var allowedHeaders = allowedHeaders();
        var allowCredentials = allowCredentials();
        var maxAge = maxAge();
        var exposedHeaders = exposedHeaders();

        var response:Response = ResponseBuilder.asStatic();

        var isOriginAllowed = false;
        if (allowedOrigins.indexOf("*") != -1 && !allowCredentials) {
            isOriginAllowed = true;
            response.header("Access-Control-Allow-Origin", "*");
        } else if (allowedOrigins.indexOf(origin) != -1) {
            isOriginAllowed = true;
            response.header("Access-Control-Allow-Origin", origin);
            response.header("Vary", "Origin");
        }

        if (!isOriginAllowed) {
            abort(403, "CORS: Origin not allowed: " + origin);
        }

        if (allowCredentials) {
            response.header("Access-Control-Allow-Credentials", "true");
        }

        if (exposedHeaders.length > 0) {
            response.header("Access-Control-Expose-Headers", exposedHeaders.join(", "));
        }

        response.header("Access-Control-Allow-Methods", allowedMethods.map(m -> m.toUpperCase()).join(", "));

        if (allowedHeaders.length > 0) {
            response.header("Access-Control-Allow-Headers", allowedHeaders.join(", "));
        }

        if (maxAge > 0) {
            response.header("Access-Control-Max-Age", Std.string(maxAge));
        }

        response.statusCode = 204;
        return response;
    }
}