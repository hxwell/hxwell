package hx.well.database.schema;

enum abstract ColumnType(String) to String {
    var TIncrements = "increments";
    var TBigIncrements = "bigIncrements";
    var TInteger = "integer";
    var TTinyInteger = "tinyInteger";
    var TSmallInteger = "smallInteger";
    var TMediumInteger = "mediumInteger";
    var TBigInteger = "bigInteger";
    var TString = "string";
    var TChar = "char";
    var TText = "text";
    var TMediumText = "mediumText";
    var TLongText = "longText";
    var TBoolean = "boolean";
    var TFloat = "float";
    var TDouble = "double";
    var TDecimal = "decimal";
    var TDate = "date";
    var TDateTime = "dateTime";
    var TTime = "time";
    var TTimestamp = "timestamp";
    var TYear = "year";
    var TJson = "json";
    var TBinary = "binary";
    var TUuid = "uuid";
    var TEnum = "enum";
    var TSet = "set";
    var TGeometry = "geometry";
}
