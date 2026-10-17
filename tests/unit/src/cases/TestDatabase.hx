package cases;

#if (neko || hl || cpp || php)
import utest.Assert;
import sys.FileSystem;
import hx.well.database.Connection;
import hx.well.database.query.QueryBuilder;
import hx.well.facades.DB;

class TestDatabase extends utest.Test {
    static var prepared:Bool = false;

    function setup() {
        if (!prepared) {
            if (FileSystem.exists("unit-test.db"))
                FileSystem.deleteFile("unit-test.db");
            Connection.create("default", {path: "unit-test.db"});
            prepared = true;
        }

        var db = new DB();
        db.query("DROP TABLE IF EXISTS tests");
        db.query("CREATE TABLE tests (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)");
    }

    function teardown() {
        Connection.free();
    }

    function builder():QueryBuilder<TestModel> {
        return new QueryBuilder(new TestModel());
    }

    function testInsertAndSelect() {
        builder().insert(["name" => "ayse"]);
        builder().insert(["name" => "baris"]);

        var rows = builder().orderBy("id").get();
        Assert.equals(2, rows.length);
        Assert.equals("ayse", rows[0].name);
        Assert.equals("baris", rows[1].name);
        Assert.equals(1, rows[0].id);
    }

    function testWhereAndFirst() {
        builder().insert(["name" => "ayse"]);
        builder().insert(["name" => "baris"]);

        var row = builder().where("name", "baris").first();
        Assert.notNull(row);
        Assert.equals("baris", row.name);

        Assert.isNull(builder().where("name", "yok").first());
    }

    function testCountAndExists() {
        builder().insert(["name" => "ayse"]);
        builder().insert(["name" => "baris"]);

        Assert.equals(2, builder().count());
        Assert.isTrue(builder().where("name", "ayse").exists());
        Assert.isFalse(builder().where("name", "yok").exists());
    }

    function testProjectionCannotReadAnotherTable() {
        var db = new DB();
        db.query("CREATE TEMP TABLE secrets (id INTEGER, name TEXT)");
        db.query("INSERT INTO secrets VALUES (42, 'PRIVATE_MARKER')");
        builder().insert(["name" => "public row"]);
        Assert.raises(() -> builder().select(["id, name FROM secrets -- "]).where("id", 1).get(), haxe.Exception);
        var row = builder().select(["tests.id", "name AS name"]).where("id", 1).first();
        Assert.equals(1, row.id);
        Assert.equals("public row", row.name);
        Assert.equals(1, builder().select(["name"]).count());
        Assert.isTrue(builder().select(["name"]).where("id", 1).exists());
        db.query("DROP TABLE secrets");
    }

    function testRawProjectionBindingsAndAggregateState() {
        builder().insert(["name" => "original"]);
        builder().insert(["name" => "other"]);
        var value = "' FROM secrets --";
        var query = builder().where("id", 1).selectRaw("id, ? AS name", value);
        var sql = query.toSelectSql();
        Assert.equals(value, query.first().name);
        Assert.equals(value, query.get()[0].name);
        Assert.equals(value, query.getResultSet().next().name);
        Assert.equals(1, query.count());
        Assert.isTrue(query.exists());
        Assert.equals(sql, query.toSelectSql());
        Assert.equals(value, query.first().name);
        Assert.equals("original", query.select(["id", "name"]).first().name);
    }

    function testUpdate() {
        builder().insert(["name" => "ayse"]);
        builder().where("name", "ayse").update(["name" => "fatma"]);

        Assert.isTrue(builder().where("name", "fatma").exists());
        Assert.isFalse(builder().where("name", "ayse").exists());
    }

    function testDelete() {
        builder().insert(["name" => "ayse"]);
        builder().insert(["name" => "baris"]);
        builder().where("name", "ayse").delete();

        Assert.equals(1, builder().count());
    }
}
#end
