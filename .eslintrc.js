module.exports = {
    parserOptions: {
    ecmaVersion: 2011,
    ecmaFeatures: {
      jsx: true
    },
    sourceType: "module"
  },
  env: {
    browser: true,
    commonjs: true,
    node: true,
  },
  extends: 'airbnb-base',
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
  },
  parserOptions: {

  },
  rules: {
  },
};