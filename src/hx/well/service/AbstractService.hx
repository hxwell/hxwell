package hx.well.service;

import sys.net.Socket;
import hx.well.http.Request;
import hx.well.http.AbstractResponse;
import hx.well.exception.AbortException;
import sys.db.Connection;
import hx.well.model.User;
import hx.well.http.RequestStatic;
import hx.well.http.RequestStatic.request;
import hx.well.http.RequestStatic.auth;
import hx.well.http.RequestStatic.socket;

abstract class AbstractService {
    public function new()
    {

    }

    public abstract function execute(request:Request):AbstractResponse;

    // Validate request data
    public function validate():Bool {
        return true;
    }

    public function connection(?key:String):Connection {
        return hx.well.database.Connection.get(key);
    }
}