window._format = (function (s) {
  if (s) {
    var outerArguments = arguments;
    return s.replace(/\{(\d+)\}/g, function () {
      return outerArguments[parseInt(arguments[1]) + 1];
    });
  }
  return '';
});
