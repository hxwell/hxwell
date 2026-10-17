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

    function testSelectRejectsSqlExpressionsAndArrayMutation() {
        for(column in ["id, name FROM secrets -- ", "id; DROP TABLE tests", "(SELECT name FROM secrets)",
            "COUNT(*)", "1", "id AS name --", "id\nFROM secrets", "name`", "a..id", "", "* AS all", null]) {
            Assert.raises(() -> builder().select([column]), Exception);
            Assert.raises(() -> TestModel.query.select([column]), Exception);
        }
        Assert.raises(() -> builder().select([]), Exception);
        Assert.raises(() -> builder().select(null), Exception);
        var columns = ["id", "name"];
        var query = builder().select(columns);
        columns[0] = "id, name FROM secrets -- ";
        Assert.equals("SELECT id, name FROM `tests`", query.toSelectSql());
        Assert.raises(() -> query.select(["id", "name FROM secrets -- "]), Exception);
        Assert.equals("SELECT id, name FROM `tests`", query.toSelectSql());
    }

    function testSelectQualifiedColumnsAliasesAndExplicitRaw() {
        Assert.equals("SELECT tests.*, tests.id AS test_id, name AS label FROM `tests`",
            builder().select(["tests.*", "tests.id as test_id", "name AS label"]).toSelectSql());
        var query = TestModel.query.where("id", 7).selectRaw("id, ? AS name", "' FROM secrets --");
        Assert.equals("SELECT id, ? AS name FROM `tests` WHERE id = ?", query.toSelectSql());
        Assert.same(["' FROM secrets --"], @:privateAccess query.selectValues);
        Assert.same([7], @:privateAccess query.values);
        Assert.equals("SELECT COUNT(*) AS cnt FROM `tests`", TestModel.query.selectRaw("COUNT(*) AS cnt").toSelectSql());
        query.select(["id"]);
        Assert.same([], @:privateAccess query.selectValues);
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
        Assert.equals("UPDATE `tests` SET `name` = ? WHERE id = ?", sql);
    }

    function testUpdateWithoutConditionRaises() {
        Assert.raises(() -> builder().toUpdateSql(["name"].iterator()), Exception);
    }

    function testInsertSql() {
        var sql = InsertQueryBuilder.toString(builder(), ["id", "name"].iterator());
        Assert.equals("INSERT INTO `tests` (`id`, `name`) VALUES (?, ?)", sql);
    }

    function testUpdateRejectsNonIdentifierColumn() {
        Assert.raises(() -> builder().where("id", 1).toUpdateSql(["is_admin = 1, name"].iterator()), Exception);
        Assert.raises(() -> builder().where("id", 1).toUpdateSql(["name`"].iterator()), Exception);
    }

    function testInsertRejectsNonIdentifierColumn() {
        Assert.raises(() -> InsertQueryBuilder.toString(builder(), ["id) VALUES (1) -- "].iterator()), Exception);
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

    function testRejectsInjectedFilterKeysAndOperators() {
        var filters:Map<String, Dynamic> = ["id = 0 OR 1=1 -- " => "ignored"];
        Assert.raises(() -> builder().where(filters), Exception);
        Assert.raises(() -> builder().orWhere(filters), Exception);
        Assert.raises(() -> builder().where("id", "= 0 OR 1=1 --", 1), Exception);
        Assert.raises(() -> builder().orWhere("id", "= ? OR 1=1 --", 1), Exception);
        for(column in ["id--", "id/*x*/", "id;DELETE", "id`", "id\nOR 1=1", "", "a..b", ".id", "id."]) {
            Assert.raises(() -> builder().where(column, 1), Exception);
        }
    }

    function testRejectsInjectedSortAndMembershipColumns() {
        Assert.raises(() -> builder().orderBy("id", "ASC, (SELECT 1)"), Exception);
        Assert.raises(() -> builder().orderBy("id DESC, name"), Exception);
        Assert.raises(() -> builder().whereIn("id) OR 1=1 --", [1]), Exception);
        Assert.raises(() -> builder().orWhereIn("id) OR 1=1 --", [1]), Exception);
        Assert.raises(() -> builder().whereNotIn("id) OR 1=1 --", []), Exception);
        Assert.raises(() -> builder().orWhereNotIn("id) OR 1=1 --", []), Exception);
    }

    function testJoinValidatesEverySqlFragment() {
        Assert.raises(() -> builder().join("INNER; --", "posts", "tests.id", "=", "posts.id"), Exception);
        Assert.raises(() -> builder().innerJoin("posts ON 1=1 --", "tests.id", "=", "posts.id"), Exception);
        Assert.raises(() -> builder().innerJoin("posts", "tests.id OR 1=1", "=", "posts.id"), Exception);
        Assert.raises(() -> builder().innerJoin("posts", "tests.id", "= 1 OR", "posts.id"), Exception);
        Assert.raises(() -> builder().innerJoin("posts", "tests.id", "=", "posts.id --"), Exception);
    }

    function testQualifiedIdentifiersAndBoundValuesStillWork() {
        var query = builder().where("tests.name", "not like", "' OR 1=1 --").orderBy("tests.id", "desc");
        Assert.equals("SELECT * FROM `tests` WHERE tests.name NOT LIKE ? ORDER BY tests.id DESC", query.toSelectSql());
        Assert.same(["' OR 1=1 --"], @:privateAccess query.values);
        Assert.equals("SELECT * FROM `tests` INNER JOIN posts ON tests.id = posts.id",
            builder().join("inner", "posts", "tests.id", "=", "posts.id").toSelectSql());
    }
}
