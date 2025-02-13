module.exports = {
    testEnvironment: 'node',
    verbose: true,
    collectCoverage: true,
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
    setupFilesAfterEnv: ['./tests/setup.js'],
    testTimeout: 60000,
    forceExit: true,
    detectOpenHandles: true
};
