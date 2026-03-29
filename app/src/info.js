const os = require('os');

function getInfo() {
    return {
        app: 'autodeploy-api',
        version: '1.2.0',
        node: process.version,
        platform: process.platform,
        arch: process.arch,
        memory: {
            total: Math.round(os.totalmem() / 1024 / 1024) + 'MB',
            free: Math.round(os.freemem() / 1024 / 1024) + 'MB'
        },
        uptime: Math.round(process.uptime()) + 's',
        timestamp: new Date().toISOString()
    };
}

module.exports = { getInfo };
