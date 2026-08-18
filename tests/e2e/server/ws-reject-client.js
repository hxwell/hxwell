const WebSocket = require('ws');

const url = process.argv[2];

const timer = setTimeout(() => {
    console.error('WS TIMEOUT waiting for rejection');
    process.exit(1);
}, 8000);

const ws = new WebSocket(url);

ws.on('open', () => ws.send('should-not-be-echoed'));

ws.on('message', (data) => {
    clearTimeout(timer);
    console.error('WS guarded route answered: ' + data.toString());
    process.exit(1);
});

ws.on('unexpected-response', () => {
    clearTimeout(timer);
    process.exit(0);
});

ws.on('close', () => {
    clearTimeout(timer);
    process.exit(0);
});

ws.on('error', () => {
    clearTimeout(timer);
    process.exit(0);
});
