package hx.well.facades;
import hx.well.http.RequestStatic.request;
import hx.well.session.SessionEnum;
import hx.well.auth.IAuthenticable;
import hx.well.session.ISession;
import hx.well.http.Request;
import hx.well.type.AttributeType;

class AuthStatic {
    public static function user<T>():T {
        return request().user();
    }

    public static function id():Null<Dynamic> {
        return request().session.get(SessionEnum.AUTH_ID);
    }

    public static function check():Bool {
        return request().attributes.exists(AttributeType.Auth);
    }

    public static function login(authenticable:IAuthenticable):Void {
        var session:ISession = request().session;
        var id:Dynamic = authenticable.getId();
        if(id == null)
        {
            throw "authenticable id cannot be null.";
        }

        session.put(SessionEnum.AUTH_ID, id);
        session.put(SessionEnum.AUTH_CLASS, Type.getClassName(Type.getClass(authenticable)));
        session.save();
    }

    public static function logout():Void {
        var session:ISession = request().session;
        session.flush();
        session.save();
    }
}
