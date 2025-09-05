package hx.well.template;
import hx.well.http.AbstractResponse;
import hx.well.http.Request;
import haxe.Exception;
import haxe.Resource;
import haxe.Template;
import hx.well.route.RouteElement;
import hx.well.facades.Compile;
import hx.well.type.AttributeType;
import hx.well.utils.StackFrameParser;
import hx.well.http.ResponseBuilder;
using hx.well.tools.MapTools;

class Status500Template extends StatusTemplate {
    public override function execute(request:Request):AbstractResponse {
        var exception:Exception = request.getAttribute(AttributeType.Exception);
        var allowDebug:Null<Bool> = request.getAttribute(AttributeType.AllowDebug);
        if(exception == null || allowDebug == null || allowDebug == false) {
            return super.execute(request);
        }

        return ResponseBuilder.asTemplate("500", {
            data: data(request, exception),
        });
    }

    private function data(request:Request, e:Exception):String {
        var routeElement:RouteElement = request.getAttribute(AttributeType.RouteElement);
        var middlewareClasses:Array<Dynamic> = request.getAttribute(AttributeType.MiddlewareClasses);

        var data = {
            stackFrames: StackFrameParser.fromException(e),
            exception: {
                name: Type.getClassName(Type.getClass(e)),
                simpleName: Type.getClassName(Type.getClass(e)).split(".").pop(),
                message: e.message,
            },
            request: {
                ip: request.ip,
                path: request.path,
                method: request.method,
                headers: @:privateAccess request.headers #if (php || js) .toDynamic() #end,
                userAgent: request.header("User-Agent", "")
            },
            route: {
                path: @:privateAccess routeElement.routePattern.getPattern(),
                middlewares: middlewareClasses.map(function(m) {
                    return Type.getClassName(m);
                }),
                service: Type.getClassName(Type.getClass(routeElement.getHandler()))
            },
            compile: Compile.all(),
            environment: {
                operatingSystem: Sys.systemName()
            }
        }
        return haxe.Json.stringify(data);
    }
}