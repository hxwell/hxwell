package hx.well.database.query;
class SelectQueryBuilder {
    /**
     * Generates an SQL SELECT statement string.
     * @param query The QueryBuilder instance containing the query state.
     * @return A formatted SQL SELECT string.
     */
    public static function toString<T>(query:QueryBuilder<T>):String {
        var sql = 'SELECT ${query.columns.join(", ")} FROM ${query.model.getTable()}';
        if (query.joins.length > 0) sql += ' ' + query.joins.join(" ");
        if (query.conditions.length > 0) sql += ' WHERE ' + query.conditions.join(" AND ");
        if (query.orderByClause != "") sql += ' ${query.orderByClause}';
        if (query.limitValue > 0) sql += ' LIMIT ${query.limitValue}';
        return sql;
    }
}