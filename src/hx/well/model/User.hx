package hx.well.model;

import hx.well.auth.IAuthenticable;

@:connection("default")
@:table("users")
@:build(hx.well.macro.ModelMacro.build())
class User extends BaseModel<User> implements IAuthenticable {
    public static var instance:User = new User();

    @:primary
    //@:visible
    @:field
    public var id:Int;

    @:visible
    @:field
    public var username:String;

    public function new() {
        super();
    }

    public function getId():Dynamic {
        return id;
    }
}