/**
 * String utility functions.
 * @namespace stringUtils
 */
window.stringUtils = (function () {
  /**
   * Formats a string.
   * @param s {string} The format string, e.g. 'Example {0} string {1}'.
   * @param arguments {...*} Replacement arguments.
   * @returns {string} The formatted string.
   */
  var format = function (s) {
    if (s) {
      var outerArguments = arguments;
      return s.replace(/{(\d+)}/g, function () {
        return outerArguments[parseInt(arguments[1]) + 1];
      });
    }
    return '';
  };

  /**
   * Formats a byte size. For example, 2048 bytes will be formatted as '2 kB'.
   * @param size {number} The size in bytes.
   * @param precision {number} Decimal precision [default 2].
   * @returns {string} The formatted size string.
   */
  var formatSize = function (size, precision) {
    if (!size || typeof size !== 'number' || size < 0) {
      return '0 B';
    }

    var constant = 1024;
    var p = precision || 2;
    var exponents = ['B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var factor = Math.floor(Math.log(size) / Math.log(constant));

    return parseFloat((size / Math.pow(constant, factor)).toFixed(p)) + ' ' + exponents[factor];
  };

  /**
   * Unescapes an HTML string, i.e. '&amp;' will be replaced with '&', '&lt;' with '<', and '&gt;' with '>'.
   * @param s {string} The HTML to unescape.
   * @returns {string} The unescaped HTML.
   */
  var unescapeHtml = function (s) {
    if (!s) {
      return '';
    }
    return s.replace(/&quot;/g, '"')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>');
  };

  /**
   * Escapes HTML in a string.
   * @param s {string} The string to HTML-escape.
   * @returns {string} The escaped HTML.
   */
  var escapeHtml = function (s) {
    if (!s) {
      return '';
    }
    return s.replace(/&quot;/g, '"')
      .replace('/&/g', '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  };

  /**
   * Formats an error message from an HTTP response.
   * @param response {Response} The HTTP response.
   * @returns {string} The formatted error message.
   */
  var getErrorMessage = function (response) {
    var message = '';
    if (!$A.util.isUndefinedOrNull(response) && !$A.util.isUndefinedOrNull(response.getError)) {
      var errors = response.getError();
      message = errors;
      if (!$A.util.isEmpty(errors)) {
        message = errors[0].message;
      }
    }

    if ($A.util.isEmpty(message)) {
      message = $A.get('$Label.c.UnknownError');
    }
    return message;
  };

  /**
   * Formats a message as HTML.
   * @param message {string|string[]} The message to format.
   * @returns {string} The HTML-formatted string.
   */
  var formatHtml = function (message) {
    if ($A.util.isEmpty(message)) return '';

    var result;
    if (Array.isArray(message)) {
      result = '<ul>';
      for (var i = 0; i < message.length; i++) {
        result += '<li>' + escapeHtml(message[i]).replace('\n', '<br/>') + '</li>'
      }
      result += '</ul>';
    } else {
      result = escapeHtml(message).replace('\n', '<br/>');
    }
    return result;
  };

  return Object.freeze({
    format: format,
    formatSize: formatSize,
    formatHtml: formatHtml,
    escapeHtml: escapeHtml,
    unescapeHtml: unescapeHtml,
    getErrorMessage: getErrorMessage
  });
}());
