
const http = require('http');
const net = require('net');
const path = require('path');
const express = require('express');
const { WebSocketServer } = require('./node_modules/ws');

const TELNET_HOST = 'localhost';
const TELNET_PORT = 1437;
// -----------------------------------

const app = express();
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws) => {
  console.log('Browser connected, opening telnet socket to', TELNET_HOST, TELNET_PORT);

  const tcpSocket = net.createConnection({ host: TELNET_HOST, port: TELNET_PORT }, () => {
    console.log('Connected to telnet server');
  });

  // Telnet -> Browser
  tcpSocket.on('data', (chunk) => {
    if (ws.readyState === ws.OPEN) {
      ws.send(chunk); // send raw bytes as a binary WebSocket frame
    }
  });

  tcpSocket.on('close', () => {
    ws.close();
  });

  tcpSocket.on('error', (err) => {
    console.error('TCP error:', err.message);
    if (ws.readyState === ws.OPEN) {
      ws.send(`\r\n*** Connection error: ${err.message}\r\n`);
      ws.close();
    }
  });

  // Browser -> Telnet
  ws.on('message', (data) => {
    tcpSocket.write(data);
  });

  ws.on('close', () => {
    tcpSocket.end();
  });

  ws.on('error', () => {
    tcpSocket.end();
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Web telnet bridge listening on http://localhost:${PORT}`);
  console.log(`Proxying to telnet://${TELNET_HOST}:${TELNET_PORT}`);
});
