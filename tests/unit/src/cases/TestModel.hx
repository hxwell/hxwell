package cases;

import hx.well.model.BaseModel;
import hx.well.model.BaseModelQuery;

@:connection("default")
@:table("tests")
class TestModel extends BaseModel<TestModel> {
    public static var query:BaseModelQuery<TestModel>;

    @:primary
    @:field
    public var id:Int;

    @:field
    public var name:String;

    public function new() {
        super();
    }
}
