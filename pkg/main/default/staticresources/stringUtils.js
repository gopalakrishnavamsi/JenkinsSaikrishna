window.stringUtils = (function () {

  var _format = function (s) {
    if (s) {
      var outerArguments = arguments;
      return s.replace(/{(\d+)}/g, function () {
        return outerArguments[parseInt(arguments[1]) + 1];
      });
    }
    return '';
  };

  var _formatSize = function (size, precision) {
    if (!size || typeof size !== 'number' || size < 0) {
      return '0 B';
    }

    var constant = 1024;
    var p = precision || 2;
    var exponents = ['B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var factor = Math.floor(Math.log(size) / Math.log(constant));

    return parseFloat((size / Math.pow(constant, factor)).toFixed(p)) + ' ' + exponents[factor];
  };

  var _unescapeHtml = function (s) {
    if (!s) {
      return '';
    }
    return s.replace(/&quot;/g, '"')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>');
  };

  return {
    format: _format,
    formatSize: _formatSize,
    unescapeHtml: _unescapeHtml
  };
}());
