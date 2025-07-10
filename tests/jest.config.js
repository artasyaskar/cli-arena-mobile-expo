/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '..', // Run tests from the project root
  testMatch: [
    '<rootDir>/tests/**/*.test.ts', // Main test directory
    '<rootDir>/tasks/**/tests/**/*.test.ts', // Task-specific tests
  ],
  moduleNameMapper: {
    // Handle module path aliases
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverage: true,
  coverageDirectory: '<rootDir>/coverage',
  coverageProvider: 'v8', // or 'babel'
  coverageReporters: ['json', 'lcov', 'text', 'clover'],
  coverageThreshold: {
    global: { // Aim for high coverage, but adjust as needed
      branches: 70, // Initially lower, will increase to 90 as per requirements
      functions: 80,
      lines: 80,
      statements: 80,
    },
    // Per-file or per-directory coverage can be specified here too
    // e.g. './src/utils/': { lines: 90 }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/jest.setup.ts'], // For global test setup
  // reporters: [ // Optional: custom reporters
  //   'default',
  //   ['jest-html-reporters', {
  //     publicPath: './coverage/html-report',
  //     filename: 'report.html',
  //     expand: true,
  //   }],
  // ],
  verbose: true, // Output more information
  // transform: {
  //   '^.+\\.tsx?$': ['ts-jest', { // ts-jest custom options
  //     tsconfig: '<rootDir>/tests/tsconfig.tests.json' // Optional: separate tsconfig for tests
  //   }]
  // }
};
