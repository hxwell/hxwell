package hx.well.type;
enum AttributeType {
    Exception;
    AllowDebug;
    RouteElement;
    MiddlewareClasses;
    DefaultGuard;
    Auth(guard:String);
}