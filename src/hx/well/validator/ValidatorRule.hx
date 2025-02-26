package hx.well.validator;
import String;
enum ValidatorRule {
    Required;
    Min(c:Int);
    Max(c:Int);
    Number; // Int && Float
    Int;
    String;
    Bool;
    Regex(r:String, opt:String);
    Custom(name:String, ?parameters:Array<Dynamic>);
}