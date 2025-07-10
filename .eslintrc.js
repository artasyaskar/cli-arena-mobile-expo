module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: [
    '@typescript-eslint',
    'jest',
    'prettier',
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:jest/recommended',
    'prettier', // Make sure this is last to override other formatting rules
  ],
  env: {
    node: true,
    jest: true,
    es2021: true,
  },
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
    project: './tsconfig.json', // Link to your tsconfig.json for type-aware linting
  },
  rules: {
    // Prettier rules
    'prettier/prettier': 'warn', // Show Prettier issues as warnings

    // TypeScript specific rules
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn', // Warn on 'any' type
    '@typescript-eslint/explicit-module-boundary-types': 'off', // Allows inferred return types for functions
    '@typescript-eslint/no-inferrable-types': 'off', // Allows explicit type declarations even when inferred

    // General ESLint rules
    'no-console': 'off', // Allow console.log for CLI tools, but consider a dedicated logger
    'no-unused-vars': 'off', // Handled by @typescript-eslint/no-unused-vars
    'eqeqeq': ['error', 'always'], // Require === and !==
    'no-implicit-coercion': 'error', // Disallow shorthand type conversions

    // Jest specific rules
    'jest/no-disabled-tests': 'warn',
    'jest/no-focused-tests': 'error',
    'jest/no-identical-title': 'error',
    'jest/prefer-to-have-length': 'warn',
    'jest/valid-expect': 'error',
  },
  settings: {
    jest: {
      version: require('jest/package.json').version,
    },
  },
  ignorePatterns: [
    'node_modules/',
    'dist/',
    'coverage/',
    '*.js', // Ignore JS files in the root (like this one, or others if any) unless explicitly included
    '!.eslintrc.js', // Don't ignore this file itself
    'jest.config.js' // Assuming Jest config is JS
  ],
};
