//Write tests here
var chai = require("chai");
var assert = chai.assert;
require("stringUtils");
describe("Sample test", function() {
  describe("escape HTML", function() {
    it("should unescape HTML ", function() {
      //var m = window.stringUtils.unescapeHtml('&amp')
      assert.isNotNull("&", window.stringUtils.unescapeHtml("&amp"));
    });
  });
});
