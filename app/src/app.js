const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const projectRoutes = require('./routes');
const { getInfo } = require('./info');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
}

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.2.0'
    });
});

app.get('/info', (req, res) => {
    res.status(200).json(getInfo());
});

app.use('/api/projects', projectRoutes);

app.get('/', (req, res) => {
    res.status(200).json({
        message: 'AutoDeploy API',
        version: '1.2.0',
        endpoints: {
            health: '/health',
            info: '/info',
            projects: '/api/projects'
        }
    });
});

app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.originalUrl} does not exist`,
        status: 404
    });
});

app.use((err, req, res, next) => {
    console.error('Unhandled error:', err.message);
    res.status(err.status || 500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message,
        status: err.status || 500
    });
});

module.exports = app;
