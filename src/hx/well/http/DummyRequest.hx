package hx.well.http;
import sys.net.Socket;
import hx.well.session.Session;
class DummyRequest extends Request {
    public function new(clientSocket:Socket) {
        super();
        this.socket = clientSocket;
        this.session = new Session();
    }
}
