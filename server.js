const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const cors = require('cors');
const net = require('net');
const connectDB = require('./config/db');

// Load env vars
dotenv.config();

const app = express();

// CORS - allow client origin(s)
const allowedOrigins = (process.env.CLIENT_URL || '').split(',').map(value => value.trim()).filter(Boolean);
allowedOrigins.push('http://localhost:5173', 'http://localhost:3000');
const uniqueOrigins = Array.from(new Set(allowedOrigins));
const allowAllOrigins = process.env.CORS_ALLOW_ALL === 'true' || process.env.NODE_ENV !== 'production';
const localhostPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i;

const isOriginAllowed = (origin) => {
    if (!origin) return true;
    if (allowAllOrigins) return true;
    if (uniqueOrigins.length === 0) return true;
    if (uniqueOrigins.includes(origin)) return true;
    if (localhostPattern.test(origin)) return true;
    return false;
};

app.use(cors({
    origin: (origin, callback) => {
        if (isOriginAllowed(origin)) {
            return callback(null, origin || true);
        }
        return callback(new Error('Not allowed by CORS'));
    },
    credentials: true
}));

// Body parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded assets
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Root route - helpful landing page for clicking links in terminal/browser
// Serve the static views folder at /views
app.use('/views', express.static(path.join(__dirname, 'views')));

// Root landing page - serve the React-based static index.html under /views
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// Routes
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/user', require('./routes/userRoutes'));
app.use('/api/hr', require('./routes/hrRoutes'));
app.use('/api/manager', require('./routes/managerRoutes'));

// If a built client exists, serve it (production). This allows you to build the
// React app into `client/dist` and let Express serve the static files.
if (process.env.NODE_ENV === 'production') {
    const clientDist = path.join(__dirname, 'client', 'dist')
    app.use(express.static(clientDist))

    // Serve index.html for unknown routes (SPA fallback)
    app.get('*', (req, res) => {
        // Don't override API routes
        if (req.path.startsWith('/api/')) return res.status(404).end()
        res.sendFile(path.join(clientDist, 'index.html'))
    })
}

// Error handler
app.use((err, req, res, next) => {
    const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
    res.status(statusCode);
    res.json({
        message: err.message,
        stack: process.env.NODE_ENV === 'production' ? null : err.stack,
    });
});

const DEFAULT_PORT = parseInt(process.env.PORT, 10) || 3000;
const MAX_PORT_ATTEMPTS = parseInt(process.env.PORT_SCAN_LIMIT || '20', 10);

const tryBinding = ({ port, host }) => new Promise((resolve, reject) => {
    const tester = net.createServer()
        .once('error', (err) => {
            tester.close();
            reject(err);
        })
        .once('listening', () => {
            tester.close(() => resolve(true));
        })
        .listen({ port, host, exclusive: true });
});

const findAvailablePort = (startPort, maxAttempts = 10) => new Promise((resolve, reject) => {
    let port = startPort;
    let attempts = 0;

    const tryPort = () => {
        Promise.resolve()
            .then(() => tryBinding({ port, host: '::' }))
            .catch((err) => {
                if (err.code === 'EADDRINUSE') return Promise.reject(err);
                // Retry with IPv4 if IPv6 not supported
                if (err.code === 'EAFNOSUPPORT' || err.code === 'EINVAL') {
                    return tryBinding({ port, host: '0.0.0.0' });
                }
                return Promise.reject(err);
            })
            .then(() => tryBinding({ port, host: '0.0.0.0' }))
            .then(() => resolve(port))
            .catch((err) => {
                if (err.code === 'EADDRINUSE') {
                    attempts += 1;
                    if (attempts >= maxAttempts) {
                        reject(new Error(`Ports ${startPort}-${port} are in use`));
                        return;
                    }
                    port += 1;
                    tryPort();
                } else {
                    reject(err);
                }
            });
    };

    tryPort();
});

const start = async () => {
    try {
        await connectDB();
        const portToUse = await findAvailablePort(DEFAULT_PORT, MAX_PORT_ATTEMPTS);
        process.env.PORT = portToUse;
        const server = app.listen({ port: portToUse, host: '0.0.0.0', exclusive: true }, () => {
            const usedPort = server.address().port;
            const url = `http://localhost:${usedPort}`;
            console.log(`Environment PORT=${process.env.PORT || '(not set)'} -> Server running on ${url}`);
            console.log(`Open ${url} in your browser (clickable in many terminals)`);
        });
    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1);
    }
};

start();