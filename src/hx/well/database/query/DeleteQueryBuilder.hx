package hx.well.database.query;
import haxe.Exception;
import hx.well.database.query.QueryBuilder.QueryCondition;

class DeleteQueryBuilder {
    /**
     * Generates an SQL DELETE statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @return A formatted SQL DELETE string.
     */
    public static function toString<T>(query:QueryBuilder<T>):String {
        if (query.joins.length > 0) throw new Exception("Delete statements do not support JOINs.");
        if (query.conditions.length == 0 && !query.queryUnsafe) throw new Exception("Delete statements must have at least one condition or be marked as unsafe.");

        var stringBuf = new StringBuf();
        stringBuf.add("DELETE FROM ");
        stringBuf.add(query.model.getTable());
        if (query.conditions.length > 0) addWhereClause(query.conditions, stringBuf);
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