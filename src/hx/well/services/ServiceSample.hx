package hx.well.services;
import hx.well.http.Request;
import sys.net.Socket;
import hx.well.http.AbstractResponse;
import hx.well.http.RequestStatic;
import hx.well.http.ResponseStatic;
import hx.well.http.JsonResponse;
import hx.well.http.ResponseStatic.*;
import hx.well.http.RequestStatic.*;
import hx.well.model.User;
import sys.db.ResultSet;
import hx.well.http.ResultSetResponse;
import hx.well.facades.DB;
import hx.well.facades.DBStatic;

class ServiceSample extends AbstractService {
    public function execute(request:Request):AbstractResponse {
        if(!auth().check())
            abort(401);

        return DBStatic.select("SELECT * FROM users WHERE username = ? and password = ?", "user2", "123");
    }
}