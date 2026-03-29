const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════╗
║   AutoDeploy API                     ║
║   Running on: http://localhost:${PORT}      ║
║   Environment: ${process.env.NODE_ENV || 'development'}            ║
║   Health: http://localhost:${PORT}/health    ║
╚══════════════════════════════════════════╝
  `);
});

// Graceful shutdown — important in containers
// When Docker sends SIGTERM (during stop/restart), the app closes cleanly
// instead of being force-killed after 10 seconds
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('Server closed.');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received. Shutting down...');
  server.close(() => {
    process.exit(0);
  });
});

module.exports = server;
