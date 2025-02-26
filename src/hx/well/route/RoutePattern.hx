package hx.well.route;

using StringTools;

class RoutePattern {
    private var pattern:String;
    private var parameters:Map<String, String>;
    private var r:String;
    private var opt:String;
    private var constraints:Map<String, String>;

    public function new(pattern:String, opt:String = "i") {
        this.pattern = pattern;
        this.parameters = new Map();
        this.constraints = new Map();
        buildRegex(pattern, opt);
    }

    private function buildRegex(pattern:String, opt:String = "i"):Void {
        var regexPattern = pattern;

        var optionalParamRegex = ~/(\/?)\{([a-zA-Z][a-zA-Z0-9_]*?)\?\}/g;
        regexPattern = optionalParamRegex.map(regexPattern, function(param) {
            var pre = param.matched(1);
            var name = param.matched(2);
            // If there is a where constraint, let's use it; otherwise default “[^/]*” (also accepts null)
            var constraint = constraints.exists(name) ? constraints.get(name) : "[^/]*";
            parameters.set(name, constraint);
            return '(?:' + (pre != "" ? pre : "") + '(${constraint}))?';
        });

        // Process mandatory parameters
        var paramRegex = ~/\{([a-zA-Z][a-zA-Z0-9_]*?)(?::([^{}]+))?\}/g;
        regexPattern = paramRegex.map(regexPattern, function(param) {
            var name = param.matched(1);
            var paramConstraint = param.matched(2);
            
            var constraint = if (constraints.exists(name)) {
                constraints.get(name);
            } else if (paramConstraint != null) {
                paramConstraint;
            } else {
                "[^/]+";
            };
            
            parameters.set(name, constraint);
            return '(${constraint})';
        });

        // We escape all “/” characters and add the start and end signs
        regexPattern = "^" + regexPattern.split("/").join("\\/") + "$";
        this.r = regexPattern;
        this.opt = opt;

        #if debug
        trace('Route pattern: ${this.r}'); // For debug
        #end
    }

    public function match(path:String):Null<Map<String, String>> {
        var regex = new EReg(r, opt);
        if (!regex.match(path)) return null;

        var params = new Map<String, String>();
        var pos = 1;
        for (param in parameters.keys()) {
            var value = regex.matched(pos);
            if (value != null && value != "") {
                params.set(param, value);
            }
            pos++;
        }
        return params;
    }

    public function getPattern():String {
        return pattern;
    }

    public function addConstraint(param:String, constraint:String):Void {
        constraints.set(param, constraint);
        buildRegex(pattern, opt); // Regenerate Regex
    }
} 