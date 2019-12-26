module.exports = {
  extends: "eslint:recommended",
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
    $A: "readonly",
    sforce: "readonly",
    UIHelper: "readonly",
    stringUtils: "readonly",
    navUtils: "readonly",
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
