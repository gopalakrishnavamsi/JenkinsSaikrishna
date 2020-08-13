module.exports = {
  extends: "eslint:recommended",
  parser: "babel-eslint",
  env: {
    browser: true,
    es6: true,
    jest: true,
    node: true
  },
  parserOptions: {
    ecmaVersion: 9,
    ecmaFeatures: {
      impliedStrict: true,
      experimentalObjectRestSpread: true
    },
    "sourceType": "module"
  },
  globals: {
    $A: "readonly",
    sforce: "readonly",
    UIHelper: "readonly",
    stringUtils: "readonly",
    navUtils: "readonly",
    historyItemTypes: "readonly",
    SpringCM: "readonly",
    Promise: "readonly",
    AgreementActionManager: "readonly",
    UserEvents: "readonly"
  },
  rules: {
    "no-shadow": "error",
    eqeqeq: "error",
    quotes: ["error", "single"]
  },
  overrides: {
    files: ["test/**/*.js"],
    globals: {
      __dirname: "readonly",
      require: "readonly",
      describe: "readonly",
      it: "readonly"
    }
  }
};
