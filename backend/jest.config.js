process.env.NODE_ENV = 'test';

const includeQuarantine = process.env.P2_03_INCLUDE_QUARANTINE === '1';
const quarantine = includeQuarantine ? [] : require('./tests/p2-03-quarantine');

module.exports = {
    testEnvironment: 'node',
    verbose: true,
    collectCoverage: false,
    coverageDirectory: 'coverage',
    coverageReporters: ['text', 'lcov'],
    coveragePathIgnorePatterns: [
        '/node_modules/',
        '/tests/fixtures/'
    ],
    testMatch: [
        '**/tests/**/*.test.js',
        '**/tests/unit/**/*.test.js'
    ],
    testPathIgnorePatterns: [
        '/node_modules/',
        ...quarantine.map((f) => f
          .replace(/\\/g, '/')
          .replace(/\./g, '\\.')
          .replace(/\//g, '[\\\\/]')),
    ],
    setupFilesAfterEnv: ['./tests/setupTests.js'],
    testTimeout: 60000,
    detectOpenHandles: false,
};
