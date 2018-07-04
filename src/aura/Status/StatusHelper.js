({
  setError: function(component, response) {
    if (component && response) {
      var errors = response.getError();
      var errMsg = errors;
      if (!$A.util.isEmpty(errors)) {
        errMsg = errors[0].message;
      }
      console.error(errMsg);
      component.set('v.errorMessage', errMsg);
    }
  },

  getNamespace: function (component) {
    var ns = '';
    if (component) {
      ns = component.get('v.controller.namespace');
    }
    return ns;
  },

  getDaysBetween: function (date) {
    if ($A.util.isEmpty(date)) {
      return null;
    }
    var dateTime = (typeof(date.getTime) === 'undefined') ? this.getJavascriptDate(date).getTime() : date.getTime();
    var today = new Date().getTime();
    var oneDay = 24 * 60 * 60 * 1000;
    return Math.floor(Math.abs((today - dateTime) / oneDay));
  },

  getJavascriptDate: function (date) {
    return new Date(date);
  }
});
