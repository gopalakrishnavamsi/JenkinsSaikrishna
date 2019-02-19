window.navUtils = (function () {

  var _isInIFrame = function () {
    var inIFrame;
    try {
      // Check to see if we can talk to the parent.
      inIFrame = window.self !== window.parent && window.parent.navUtils && (!!parent.navUtils.isInIFrame);
    } catch (e) {
      inIFrame = false;
    }
    return inIFrame;
  };

  var _isLightningOrMobile = function () {
    return typeof sforce !== 'undefined' && sforce && (!!sforce.one);
  };

  var _isInNewWindow = function () {
    return (!!window.opener);
  };

  var _navigateToSObject = function (id, pathPrefix) {
    if (_isInIFrame()) {
      window.parent.navUtils.navigateToSObject(id, pathPrefix);
    } else if (_isLightningOrMobile()) {
      sforce.one.navigateToSObject(id);
    } else {
      window.location.href = (!!pathPrefix) ? pathPrefix + '/' + id : '/' + id;
    }
  };

  var _navigateToUrl = function (url) {
    var navEvt = $A.get('e.force:navigateToURL');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'url': url
      });
      navEvt.fire();
    }
  };

  return {
    isInIFrame: _isInIFrame,
    isLightningOrMobile: _isLightningOrMobile,
    isInNewWindow: _isInIFrame,
    navigateToSObject: _navigateToSObject,
    navigateToUrl: _navigateToUrl
  };
}());
