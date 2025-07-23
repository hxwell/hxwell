package hx.well.database.query;
import hx.well.database.query.QueryBuilder.QueryCondition;
class SelectQueryBuilder {
    /**
     * Generates an SQL SELECT statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @return A formatted SQL SELECT string.
     */
    public static function toString<T>(query:QueryBuilder<T>):String {
        var stringBuf = new StringBuf();
        stringBuf.add("SELECT ");
        stringBuf.add(query.columns.join(", "));
        stringBuf.add(" FROM ");
        stringBuf.add(query.model.getTable());

        if (query.joins.length > 0) {
            stringBuf.add(" ");
            stringBuf.add(query.joins.join(" "));
        }
        if (query.conditions.length > 0) addWhereClause(query.conditions, stringBuf);
        if (query.orderByClause != "") {
            stringBuf.add(" ");
            stringBuf.add(query.orderByClause);
        }
        if (query.limitValue > 0) {
            stringBuf.add(" LIMIT ");
            stringBuf.add(query.limitValue);
        }
        return stringBuf.toString();
    }

    private static function addWhereClause(conditions:Array<QueryCondition>, stringBuf:StringBuf):Void {
        stringBuf.add(" WHERE ");
        stringBuf.add(conditions[0].condition);
        for (i in 1...conditions.length) {
            stringBuf.add(" ");
            stringBuf.add(conditions[i].type);
            stringBuf.add(" ");
            stringBuf.add(conditions[i].condition);
        }
    }
}