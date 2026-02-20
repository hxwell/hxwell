package hx.well.middleware;

import hx.well.http.Request;
import hx.well.http.Response;
import hx.well.http.ResponseBuilder;

/**
 * Abstract CORS middleware that handles both preflight (OPTIONS) and actual requests.
 *
 * Subclasses must implement `allowedOrigins()`. All other configuration methods
 * have sensible defaults that can be overridden as needed.
 *
 * Usage:
 *   class MyCorsMiddleware extends AbstractCorsMiddleware {
 *       public override function allowedOrigins():Array<String> {
 *           return ["https://example.com", "https://app.example.com"];
 *       }
 *   }
 */
abstract class AbstractCorsMiddleware extends AbstractMiddleware {
    /**
	 * The list of allowed origins for CORS requests.
	 * Example: `["https://example.com", "https://another-domain.com"]`.
	 * Use `["*"]` to allow all origins, but this is not recommended if `allowCredentials()` returns `true`.
	 */
    public abstract function allowedOrigins():Array<String>;

    /**
	 * The list of allowed HTTP methods.
	 * Defaults to common methods: GET, POST, PUT, PATCH, DELETE, OPTIONS.
	 */
    public function allowedMethods():Array<String> {
        return ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"];
    }

    /**
	 * The list of allowed HTTP headers for preflight requests.
	 * Defaults to commonly used headers.
	 */
    public function allowedHeaders():Array<String> {
        return ["Content-Type", "Authorization", "X-Requested-With", "Accept", "Origin"];
    }

    /**
	 * Indicates whether the response to the request can be exposed when the credentials flag is true.
	 * If `true`, the `Access-Control-Allow-Origin` header cannot be `"*"`.
	 * Defaults to `false`.
	 */
    public function allowCredentials():Bool {
        return false;
    }

    /**
	 * The value of the `Access-Control-Max-Age` header in seconds.
	 * Specifies how long the results of a preflight request can be cached.
	 * Defaults to 86400 (24 hours).
	 */
    public function maxAge():Int {
        return 86400;
    }

    /**
	 * The list of headers that can be exposed as part of the response by listing their names.
	 * Example: `["Content-Length", "X-Custom-Header"]`.
	 * Defaults to an empty array.
	 */
    public function exposedHeaders():Array<String> {
        return [];
    }

    /**
	 * The main handler function for the middleware.
	 * Adds CORS headers to all responses and handles preflight (OPTIONS) requests
	 * by returning a 204 No Content response with the appropriate headers.
	 */
    public function handle(request:Request, next:Request -> Null<Response>):Null<Response> {
        var origin = request.header("Origin");

        // No Origin header means this is not a CORS request; pass through.
        if (origin == null) {
            return next(request);
        }

        // Gather configuration (avoid variable names shadowing method names).
        var origins = allowedOrigins();
        var methods = allowedMethods();
        var headers = allowedHeaders();
        var credentials = allowCredentials();
        var age = maxAge();
        var exposed = exposedHeaders();

        // Determine if wildcard is configured and whether the request origin is allowed.
        var isWildcardConfig = origins.indexOf("*") != -1;
        var isOriginAllowed = isWildcardConfig || origins.indexOf(origin) != -1;

        // Per spec: Access-Control-Allow-Origin cannot be "*" when credentials are enabled.
        // In that case, echo back the actual origin instead.
        var useWildcardHeader = isWildcardConfig && !credentials;

        // If the origin is not allowed, reject with 403 Forbidden.
        if (!isOriginAllowed) {
            trace("origin is not allowed, reject with 403 Forbidden.", origins);
            var response:Response = ResponseBuilder.asStatic();
            response.statusCode = 403;
            return response;
        }

        // Handle preflight (OPTIONS) requests.
        if (request.method == "OPTIONS") {
            return handlePreflight(request, origin, useWildcardHeader, methods, headers, credentials, age, exposed);
        }

        // Handle actual (non-preflight) requests: add CORS headers to the real response.
        var response = next(request);
        if (response != null) {
            addOriginHeader(response, origin, useWildcardHeader);

            if (credentials) {
                response.header("Access-Control-Allow-Credentials", "true");
            }

            if (exposed.length > 0) {
                response.header("Access-Control-Expose-Headers", exposed.join(", "));
            }
        }

        return response;
    }

    /**
	 * Handles a CORS preflight (OPTIONS) request by returning a 204 No Content response
	 * with all necessary CORS headers.
	 */
    private function handlePreflight(request:Request, origin:String, isWildcard:Bool, methods:Array<String>, headers:Array<String>, credentials:Bool, age:Int,
                                     exposed:Array<String>):Response {
        var response:Response = ResponseBuilder.asStatic();

        // Validate Access-Control-Request-Method if present.
        var requestMethod = request.header("Access-Control-Request-Method");
        if (requestMethod != null) {
            var upperMethods = methods.map(m -> m.toUpperCase());
            if (upperMethods.indexOf(requestMethod.toUpperCase()) == -1) {
                trace('Requested method "${requestMethod}" is not allowed by CORS policy, reject with 403 Forbidden.');
                response.statusCode = 403;
                return response;
            }
        }

        // Set the origin header.
        addOriginHeader(response, origin, isWildcard);

        // Allow credentials.
        if (credentials) {
            response.header("Access-Control-Allow-Credentials", "true");
        }

        // Expose headers.
        if (exposed.length > 0) {
            response.header("Access-Control-Expose-Headers", exposed.join(", "));
        }

        // Allowed methods.
        response.header("Access-Control-Allow-Methods", methods.map(m -> m.toUpperCase()).join(", "));

        // Allowed headers.
        if (headers.length > 0) {
            response.header("Access-Control-Allow-Headers", headers.join(", "));
        }

        // Max age.
        if (age > 0) {
            response.header("Access-Control-Max-Age", Std.string(age));
        }

        response.statusCode = 204;
        return response;
    }

    /**
	 * Sets the `Access-Control-Allow-Origin` and `Vary` headers on the response.
	 * For wildcard origins, sets `*` without Vary. For specific origins, sets the
	 * origin value and adds `Vary: Origin` for correct caching behavior.
	 */
    private function addOriginHeader(response:Response, origin:String, isWildcard:Bool):Void {
        if (isWildcard) {
            response.header("Access-Control-Allow-Origin", "*");
        }
        else {
            response.header("Access-Control-Allow-Origin", origin);
            response.header("Vary", "Origin");
        }
    }
}
