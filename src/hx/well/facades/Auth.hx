package hx.well.facades;
import hx.well.http.Request;
import hx.well.auth.IAuthenticatable;
import hx.well.session.ISession;
import hx.well.session.SessionDataType;
import hx.well.type.AttributeType;
import haxe.ds.StringMap;

class Auth {
    private var request:Request;
    private var guard:String;

    public function new(request:Request, guard:String) {
        this.request = request;
        this.guard = guard;
    }

    public function user<T>():T {
        return request.user();
    }

    public function id():Null<Dynamic> {
        return request.session.getWithEnum(SessionDataType.AUTH_ID(guard));
    }

    public function check():Bool {
        return request.existsAttribute(AttributeType.Auth(guard));
    }

    public function attempt(credentials:StringMap<Dynamic>):Bool {
        credentials = credentials.copy(); // avoid modifying the original map

        var password = credentials.get("password");
        credentials.remove("password");

        var query:Dynamic = Reflect.getProperty(getModelClass(), "query");
        var authenticatable:IAuthenticatable = query.where(credentials).first();
        if (authenticatable == null || !Hash.check(password, authenticatable.getPassword()))
            return false;

        trace(authenticatable);

        login(authenticatable);
        return true;
    }

    public function login(authenticable:IAuthenticatable):Void {
        var session:ISession = request.session;
        var id:Dynamic = authenticable.getId();
        if(id == null)
        {
            throw "authenticable id cannot be null.";
        }

        session.putWithEnum(SessionDataType.AUTH_ID(guard), id);
        session.save();

        request.setAttribute(AttributeType.Auth(guard), authenticable);
    }

    private function getModelClass():Class<IAuthenticatable> {
        return Config.get("session.guards").get(guard);
    }

    public function  logout():Void {
        var session:ISession = request.session;
        session.flush();
        session.save();
    }
}
