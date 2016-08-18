package blockly.backend.flask;

import haxe.Template;
import python.flask.HttpStatus;
import python.flask.Flask;
import python.flask.Request;
import python.flask.HttpMethod;

class Main {
    static var app: Flask;

    static function main() {
        app = new Flask(untyped __name__);
        app.route("/")(index);
        app.route("/store")(listStore);
        app.route("/store/<key>", {methods:[HttpMethod.GET, HttpMethod.POST]})(workspaceStore);
        app.debug = true;
        app.run();
    }

    static function workspaceStore(key: String): Dynamic {
        if( Request.method == HttpMethod.GET ) {
            try {
                return sys.io.File.getBytes('storage/$key').toString();
            }
            catch(e:Dynamic) {
                var resp = app.make_response('$key: $e');
                resp.status_code = HttpStatus.NOT_FOUND;
                return resp;
            }
        }
        else if( Request.method == HttpMethod.POST ) {
            sys.io.File.saveBytes('storage/$key', haxe.io.Bytes.ofData(Request.data));
            return "OK";
        }

        var resp = app.make_response("invalid method");
        resp.status_code = HttpStatus.METHOD_NOT_ALLOWED;
        return resp;
    }

    static function listStore(): Dynamic {
        try {
            var fileNames = sys.FileSystem.readDirectory('storage')
                .filter(function(n){ return n.charAt(0) != '.'; })
                .map(function(n){return {name: n};});
            return listTemplate.execute({files: fileNames});
        }
        catch(e: Dynamic) {
            var resp = app.make_response('could not list store: $e');
            resp.status_code = HttpStatus.NOT_FOUND;
            return resp;
        }
    }

    static function index() {
        var bodyType = untyped str(type(Request.data));
        return "Hello, world !!! " + bodyType + "  " + Sys.getCwd();
    }

    static var listTemplate = new Template(
'<html>
    <head><title>Stored Files</title></head>
    <body>
        <ul>
            ::foreach files::
            <li><a href="/store/::name::">::name::</a></li>
            ::end::
        </ul>
    </body>
</html>'
    );
}