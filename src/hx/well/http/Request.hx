package hx.well.http;

import haxe.io.Bytes;
import hx.well.session.ISession;
using StringTools;
import hx.well.request.AbstractRequestBody;
import hx.well.request.ParameterRequestBody;
import hx.well.validator.ValidatorRule;
import hx.well.facades.Validator;
import hx.well.type.AttributeType;
import hx.well.http.driver.IDriverContext;
import haxe.ds.StringMap;
import hx.well.request.JsonRequestBody;

@:allow(hx.well.http.HttpHandler)
@:allow(hx.well.http.driver.socket.SocketRequestParser)
@:allow(hx.well.http.RequestParser)
@:allow(hx.well.http.driver.IDriverContext)
class Request {
    public var ip:String;
    public var host:String;
    public var method: String;
    public var path(default, set): String;

    private function set_path(value:String):String {
        this.queries = RequestParser.parseQueryString(value);

        var queryIndex = value.indexOf("?");
        if(queryIndex != -1)
            value = value.substring(0, queryIndex);

        return this.path = value;
    }

    public var version: String;
    private var headers:Map<String, String> = new Map<String, String>();
    private var cookies:Map<String, String> = new Map<String, String>();
    public var requestBytes: Bytes;
    public var bodyBytes: Bytes;
    public var context:IDriverContext;
    public var session:ISession;
    private var attributes(default, null):Map<String, Dynamic> = new Map();
    private var routeParameters(default, null):Map<String, String>;
    //public var body: String ;

    private var _parsedBody:Null<AbstractRequestBody>;
    public var queries:Map<String, String>;

    private var routeParams:Map<String, String>;

    public function new() {
        #if debug
            setAttribute(AttributeType.AllowDebug, true);
        #end
        setAttribute(AttributeType.DefaultGuard, "default");
    }

    public overload extern inline function getAttribute<T>(key:EnumValue, defaultValue:T = null):T {
        return attributes.get('${key}') ?? defaultValue;
    }

    public overload extern inline function getAttribute<T>(key:String, defaultValue:T = null):T {
        return attributes.get(key) ?? defaultValue;
    }

    public overload extern inline function setAttribute(key:EnumValue, value:Dynamic):Void {
        attributes.set('${key}', value);
    }

    public overload extern inline function setAttribute(key:String, value:Dynamic):Void {
        attributes.set(key, value);
    }

    public overload extern inline function existsAttribute(key:String):Bool {
        return attributes.exists(key);
    }

    public overload extern inline function existsAttribute(key:EnumValue):Bool {
        return attributes.exists('${key}');
    }

    public function currentGuard():String {
        return getAttribute(AttributeType.DefaultGuard);
    }

    public function user<T>(guard:String = null):T {
        if(guard == null) guard = currentGuard();

        return getAttribute(AttributeType.Auth(guard));
    }

    public function route(key:String, ?defaultValue:String):String {
        return routeParameters.get(key) ?? defaultValue;
    }

    public function cookie(key:String, ?defaultValue:String):String {
        return cookies.get(key) ?? defaultValue;
    }

    public function header(key:String, ?defaultValue:String):String {
        return headers.get(key) ?? defaultValue;
    }

    public function all():StringMap<Dynamic>  {
        var result:StringMap<Dynamic> = new StringMap<Dynamic>();
        
        // Query parametrelerini ekle
        for (iterator in queries.keyValueIterator()) {
            result.set(iterator.key, iterator.value);
        }

        var body:AbstractRequestBody = _parsedBody;
        if (body != null) {
            if(body is ParameterRequestBody) {
                var parameterRequestBody:ParameterRequestBody = cast body;
                for (keyValueIterator in parameterRequestBody.map().keyValueIterator()) {
                    result.set(keyValueIterator.key, keyValueIterator.value);
                }
            }else if(body is JsonRequestBody) {
                var jsonRequestBody:JsonRequestBody = cast body;
                for (key in jsonRequestBody.keys()) {
                    var value:Dynamic = jsonRequestBody.get(key);
                    result.set(key, value);
                }
            }

        }
        
        return result;
    }

    public function only(...keys:String):StringMap<Dynamic> {
        var result:StringMap<Dynamic> = new StringMap<Dynamic>();

        for (key in keys)
            if(queries.exists(key))
                result.set(key, queries.get(key));


        var body:AbstractRequestBody = _parsedBody;
        if (body != null) {
            if(body is ParameterRequestBody)
            {
                var parameterRequestBody:ParameterRequestBody = cast body;
                for (key in keys)
                    if(parameterRequestBody.exists(key))
                        result.set(key, parameterRequestBody.get(key));
            }
            else if(body is JsonRequestBody)
            {
                var jsonRequestBody:JsonRequestBody = cast body;
                for (key in keys)
                    if(jsonRequestBody.exists(key))
                        result.set(key, jsonRequestBody.get(key));
            }
        }

        return result;
    }

    public function input(key:String, ?defaultValue:Dynamic):Dynamic {
        var body = _parsedBody;
        if (body != null) {
            return body.get(key) ?? defaultValue;
        }

        var queryValue = query(key);
        return queryValue ?? defaultValue;
    }

    public function query(key:String, ?defaultValue:String):String {
        return queries.exists(key) ? queries.get(key) : defaultValue;
    }

    public function post<T>(?key:String, ?defaultValue:T):T {
        var body = _parsedBody;
        if (body == null) return defaultValue;

        return body.exists(key) ? body.get(key) : defaultValue;
    }

    public function has(key:String):Bool {
        var body = _parsedBody;
        return body.exists(key) || queries.exists(key);
    }

    public function validate(data:Map<String, Array<ValidatorRule>>):Bool {
        for (key in data.keys()) {
            var validatorRules = data.get(key);
            var value:Dynamic = input(key);
            if (Lambda.exists(validatorRules, rule -> rule == ValidatorRule.Required) || value != null) {
                for (validatorRule in validatorRules) {
                    if (!validateRule(key, value, validatorRule)) return false;
                }
            }
        }
        return true;
    }

    private function validateRule(attribute:String, value:Dynamic, rule:ValidatorRule):Bool {
        if (value == null) return false;

        switch (rule) {
            case Required:
            case Min(c):
                if ((value is String && (value : String).length < c) || (value is Int && (value : Int) < c) || (value is Float && (value : Float) < c)) return false;
            case Max(c):
                if ((value is String && (value : String).length > c) || (value is Int && (value : Int) > c) || (value is Float && (value : Float) > c)) return false;
            case Int:
                if (!(value is Int)) return false;
            case Number:
                if (!(value is Int) && !(value is Float)) return false;
            case String:
                if (!(value is String)) return false;
            case Bool:
                if (!(value is Bool)) return false;
            case Email:
                var emailPattern = new EReg("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", "");
                if (!emailPattern.match(Std.string(value))) return false;
            case Regex(r, opt):
                if (!new EReg(r, opt ?? "").match(Std.string(value))) return false;
            case Custom(name, params):
                return Validator.validate(name, attribute, value, params);
        }
        return true;
    }

    public function param(key:String, ?defaultValue:String):String {
        return routeParams != null ? routeParams.get(key) ?? defaultValue : defaultValue;
    }

    public function setRouteParams(params:Map<String, String>) {
        this.routeParams = params;
    }
}