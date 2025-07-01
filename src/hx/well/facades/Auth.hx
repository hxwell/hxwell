package hx.well.facades;
import hx.well.http.Request;
import hx.well.auth.IAuthenticable;
import hx.well.session.ISession;
import hx.well.session.SessionEnum;
import hx.well.type.AttributeType;
class Auth {
    private var request:Request;

    public function new(request:Request) {
        this.request = request;
    }

    public function user<T>():T {
        return request.user();
    }

    public function id():Null<Dynamic> {
        return request.session.get(SessionEnum.AUTH_ID);
    }

    public function check():Bool {
        return request.attributes.exists(AttributeType.Auth);
    }

    public function login(authenticable:IAuthenticable):Void {
        var session:ISession = request.session;
        var id:Dynamic = authenticable.getId();
        if(id == null)
        {
            throw "authenticable id cannot be null.";
        }

        session.put(SessionEnum.AUTH_ID, id);
        session.put(SessionEnum.AUTH_CLASS, Type.getClassName(Type.getClass(authenticable)));
        session.save();
    }

    public function  logout():Void {
        var session:ISession = request.session;
        session.flush();
        session.save();
    }
}
