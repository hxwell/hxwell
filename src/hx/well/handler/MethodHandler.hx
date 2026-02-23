package hx.well.handler;

import hx.well.http.RequestStatic;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import hx.well.http.ResponseStatic.abort;
import hx.well.validator.ValidatorRule;

/**
 * Object-based method call handler
 * Use:
 * 1. When a method implemented by inheriting this class has a signature matching Request->AbstractResponse, it will automatically add new API access support
 * 2. Add @:get, @:post annotations on methods to specify HTTP methods
 * 3. When the method doesn't exist, it will redirect to a 404 page
 * 4. When the HTTP method doesn't match, it will redirect to a 405 page
 * 5. Add @:validator annotations on methods to specify validation rules
 * ```haxe
 *  class MyHandler extends MethodHandler {
 *      @:get
 *      @:post
 * 		@:validator("data", [ValidatorRule.Required])
 *      public function hello(request:Request):AbstractResponse {
 *          return "hello world";
 *      }
 *  }
 * ```
 * 6. Add the handler to the router, the last part of the address will be the method name
 * ```haxe
 * Route.any("/user/{method}").handler(new MyHandler());
 * ```
 */
@:autoBuild(hx.well.macro.MethodHandlerMacro.build())
class MethodHandler extends AbstractHandler {
	/**
	 * Map method names to HTTP methods
	 */
	public var methods:Map<String, MethodHandlerFunction> = [];

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
		var methodFunction = requestMethodFunction(request);
		if (methodFunction != null) {
			if (methodFunction.method == "ANY" || methodFunction.method == httpMethod) {
				return Reflect.callMethod(this, methodFunction.callback, [request]);
			} else {
				abort(405, "method not allowed");
			}
		}
		abort(404, "method not found");
	}

	/**
	 * Get the method function based on the request
	 */
	public function requestMethodFunction(?request:Request):MethodHandlerFunction {
		var path = request.path;
		var method = path.split("/").pop();
		var methodFunction = methods.exists(method) ? Reflect.field(this, method) : null;
		if (methodFunction == null) {
			return null;
		}
		var methodHandlerFunction = methods[method];
		if (methodHandlerFunction.callback == null) {
			methodHandlerFunction.callback = methodFunction;
		}
		return methodHandlerFunction;
	}

	override function validate():Bool {
		var request = RequestStatic.request();
		var methodFunction = requestMethodFunction(request);
		if (methodFunction != null) {
			var v = request.validate(methodFunction.validators);
			return v;
		}
		return super.validate();
	}
}

typedef MethodHandlerFunction = {
	method:String,
	validators:Map<String, Array<ValidatorRule>>,
	?callback:Request->AbstractResponse
}
