package hx.well.handler;

import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.abort;

/**
 * Object-based method call handler
 */
@:autoBuild(hx.well.macro.MethodHandlerMacro.build())
class MethodHandler extends AbstractHandler {
	/**
	 * Map method names to HTTP methods
	 */
	public var methods:Map<String, String> = [];

	public function new() {
		super();
		__internal();
	}

	/**
	 * Internal method used to initialize methods
	 */
	private function __internal() {}

	public function execute(request:Request):AbstractResponse {
		var httpMethod = request.method.toUpperCase();
		var path = request.path;
		var method = path.split("/").pop();
		var methodFunction = methods.exists(method) ? Reflect.field(this, method) : null;
		if (methodFunction == null) {
			abort(404, "method not found");
		} else {
			if (methods[method] == "ANY" || methods[method] == httpMethod) {
				return Reflect.callMethod(this, methodFunction, [request]);
			} else {
				abort(405, "method not allowed");
			}
		}
		return method;
	}
}
