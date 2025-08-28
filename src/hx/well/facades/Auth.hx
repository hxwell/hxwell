package hx.well.facades;
import hx.well.http.Request;
import hx.well.auth.IAuthenticatable;
import hx.well.session.ISession;
import hx.well.session.SessionEnum;
import hx.well.type.AttributeType;
import haxe.ds.StringMap;
import hx.well.model.User;
import hx.well.model.BaseModel;

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

    public function attempt(credentials:StringMap<Dynamic>):Bool {
        credentials = credentials.copy(); // avoid modifying the original map

        var password = credentials.get("password");
        credentials.remove("password");

        var authenticatableInstance:BaseModel<IAuthenticatable> = cast User.instance;
        var authenticatable:IAuthenticatable = authenticatableInstance.where(credentials).first();
        if(authenticatable == null || !Hash.check(password, authenticatable.getPassword()))
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

        session.put(SessionEnum.AUTH_ID, id);
        session.put(SessionEnum.AUTH_CLASS, Type.getClassName(Type.getClass(authenticable)));
        session.save();

        request.attributes.set(AttributeType.Auth, authenticable);
    }

    public function  logout():Void {
        var session:ISession = request.session;
        session.flush();
        session.save();
    }
}
