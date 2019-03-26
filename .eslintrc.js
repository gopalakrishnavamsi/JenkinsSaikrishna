module.exports = {
  extends: 'eslint:recommended',
  env: {
    browser: true
  },
  parserOptions: {
    ecmaVersion: 5,
    ecmaFeatures: {
      impliedStrict: true
    }
  },
  globals: {
    $A: 'readonly',
    sforce: 'readonly',
    UIHelper: 'readonly',
    stringUtils: 'readonly',
    navUtils: 'readonly',
    SpringCM: 'readonly'
  },
  rules: {
    'no-shadow': 'error'
  }
};
