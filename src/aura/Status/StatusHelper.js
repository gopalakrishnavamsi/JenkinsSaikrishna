({
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
