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
