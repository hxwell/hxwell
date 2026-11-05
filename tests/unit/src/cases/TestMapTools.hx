package cases;

import hx.well.tools.MapTools;
import utest.Assert;
import utest.Test;

class TestMapTools extends Test {
    function testToDynamicReturnsFields() {
        var source:Map<String, Dynamic> = ["title" => "Example", "count" => 2];
        var record = MapTools.toDynamic(source);
        Assert.equals("Example", record.title);
        Assert.equals(2, record.count);
    }
}
