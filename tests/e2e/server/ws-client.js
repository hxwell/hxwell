const WebSocket = require('ws');

const url = process.argv[2];
const message = process.argv[3];

const timer = setTimeout(() => {
    console.error('WS TIMEOUT');
    process.exit(1);
}, 8000);

const ws = new WebSocket(url);

ws.on('open', () => ws.send(message));

ws.on('message', (data) => {
    if (data.toString() === 'echo:' + message) {
        clearTimeout(timer);
        ws.close();
        process.exit(0);
    }
    console.error('WS unexpected reply: ' + data.toString());
    process.exit(1);
});

ws.on('error', (err) => {
    console.error('WS error: ' + err.message);
    process.exit(1);
});
