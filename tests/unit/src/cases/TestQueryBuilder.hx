package cases;

import utest.Assert;
import hx.well.database.query.QueryBuilder;
import hx.well.database.query.InsertQueryBuilder;
import hx.well.database.query.UpdateQueryBuilder;
import hx.well.database.query.DeleteQueryBuilder;
import haxe.Exception;

class TestQueryBuilder extends utest.Test {
    function builder():QueryBuilder<TestModel> {
        return new QueryBuilder(new TestModel());
    }

    function testSelectAll() {
        Assert.equals("SELECT * FROM `tests`", builder().toSelectSql());
    }

    function testSelectColumns() {
        Assert.equals("SELECT id, name FROM `tests`", builder().select(["id", "name"]).toSelectSql());
    }

    function testWhere() {
        var sql = builder().where("id", 1).where("name", "!=", "x").toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE id = ? AND name != ?", sql);
    }

    function testOrWhere() {
        var sql = builder().where("id", 1).orWhere("name", "x").toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE id = ? OR name = ?", sql);
    }

    function testWhereIn() {
        var sql = builder().whereIn("id", [1, 2, 3]).toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE id IN (?,?,?)", sql);
    }

    function testWhereInEmpty() {
        var sql = builder().whereIn("id", []).toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE 1=0", sql);
    }

    function testWhereNotIn() {
        var sql = builder().whereNotIn("id", [1, 2]).toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE id NOT IN (?,?)", sql);
    }

    function testJoin() {
        var sql = builder().innerJoin("posts", "tests.id", "=", "posts.test_id").toSelectSql();
        Assert.equals("SELECT * FROM `tests` INNER JOIN posts ON tests.id = posts.test_id", sql);
    }

    function testOrderByAndLimit() {
        var sql = builder().orderBy("id", "DESC").limit(5).toSelectSql();
        Assert.equals("SELECT * FROM `tests` ORDER BY id DESC LIMIT 5", sql);
    }

    function testDeleteSql() {
        var sql = builder().where("id", 1).toDeleteSql();
        Assert.equals("DELETE FROM `tests` WHERE id = ?", sql);
    }

    function testDeleteWithoutConditionRaises() {
        Assert.raises(() -> builder().toDeleteSql(), Exception);
    }

    function testDeleteUnsafe() {
        Assert.equals("DELETE FROM `tests`", builder().unsafe(true).toDeleteSql());
    }

    function testUpdateSql() {
        var sql = builder().where("id", 1).toUpdateSql(["name"].iterator());
        Assert.equals("UPDATE `tests` SET name = ? WHERE id = ?", sql);
    }

    function testUpdateWithoutConditionRaises() {
        Assert.raises(() -> builder().toUpdateSql(["name"].iterator()), Exception);
    }

    function testInsertSql() {
        var sql = InsertQueryBuilder.toString(builder(), ["id", "name"].iterator());
        Assert.equals("INSERT INTO `tests` (id, name) VALUES (?, ?)", sql);
    }

    function testInsertWithConditionRaises() {
        Assert.raises(() -> InsertQueryBuilder.toString(builder().where("id", 1), ["name"].iterator()), Exception);
    }

    function testInsertWithoutColumnsRaises() {
        Assert.raises(() -> InsertQueryBuilder.toString(builder(), [].iterator()), Exception);
    }

    function testWhereRaw() {
        var sql = builder().whereRaw("id > ? AND id < ?", 1, 10).toSelectSql();
        Assert.equals("SELECT * FROM `tests` WHERE id > ? AND id < ?", sql);
    }
}
