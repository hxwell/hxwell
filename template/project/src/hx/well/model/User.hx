package hx.well.model;

import hx.well.auth.IAuthenticatable;
import hx.well.model.BaseModel;

@:connection("default")
@:table("users")
@:build(hx.well.macro.ModelMacro.build())
class User extends BaseModel<User> implements IAuthenticatable {
    public static var instance:User;

    @:primary
    //@:visible
    @:field
    public var id:Int;

    @:visible
    @:field
    public var username:String;

    //@:visible
    @:field
    public var password:String;

    public function new() {
        super();
    }

    public function getId():Dynamic {
        return id;
    }

    public function getPassword():String {
        return password;
    }
}