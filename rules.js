/* Rules for ESLint */

const rules ={

};
function extendRules(overrides) {
  return Object.assign({}, rules, overrides);
}
module.exports = {
  extend: extendRules
};

