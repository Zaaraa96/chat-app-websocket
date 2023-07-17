import express, { Request, Response, NextFunction } from 'express';
import WebSocket from 'ws';
import jwt from 'jsonwebtoken';
import cors from 'cors';

const app = express();

app.use(
    cors({
        origin: function (origin, callback) {
            return callback(null, true);
        },
    })
);

// Set up JWT secret key
const secretKey = 'your_secret_key';

// Create an HTTP server using Express
const server = app.listen(3000, () => {
    console.log('Server listening on port 3000');
});

// Create a WebSocket server using the HTTP server
const wss = new WebSocket.Server({ server });

// Store connected clients
const clients = new Set<WebSocket>();

interface Message {
    user: string;
    text: string;
}

const messages: Message[] = [];

// WebSocket server connection handling
wss.on('connection', (ws) => {
    // Add the new client to the clients set
    clients.add(ws);
    console.log('New client connected');
    ws.send(JSON.stringify({ previous_messages: messages }));

    // Handle WebSocket messages
    ws.on('message', (message) => {
        try {
            const parsedMessage = JSON.parse(message.toString()) as { token: string; text: string };
            const decoded = jwt.verify(parsedMessage.token, secretKey) as { user: string };
            console.log('Received message:', parsedMessage.text, 'with token of user', decoded);
            const to_send_data: Message = { user: decoded.user, text: parsedMessage.text };
            messages.push(to_send_data);
            broadcast(JSON.stringify({ message: to_send_data }));
        } catch (err) {
            console.error('Error decoding message:', err);
        }
    });

    // Handle WebSocket disconnection
    ws.on('close', () => {
        // Remove the disconnected client from the clients set
        clients.delete(ws);
        console.log('Client disconnected');
    });
});

// Broadcast a message to all connected clients
function broadcast(message: string) {
    clients.forEach((client) => {
        client.send(message);
    });
}

// Express route for generating a JWT
app.get('/token', (req: Request, res: Response) => {
    const name = req.query.name as string;
    if (!name) return res.status(401).send('unauthorized');
    const token = jwt.sign({ user: name }, secretKey);
    res.json({ token });
});

// Express error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err);
    res.status(500).send('Internal Server Error');
});
