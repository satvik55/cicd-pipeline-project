module.exports = {
  // Where to find tests
  testMatch: ['**/tests/**/*.test.js'],

  // Set NODE_ENV to 'test' (suppresses morgan logging during tests)
  testEnvironment: 'node',

  // Coverage settings — shows which lines your tests actually execute
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js'  // exclude server startup file from coverage
  ],

  // Timeout per test (default is 5000ms, increase if slow CI)
  testTimeout: 10000
};
