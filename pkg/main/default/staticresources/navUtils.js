/**
 * Navigation utility methods.
 * @namespace navUtils
 */
window.navUtils = (function () {
  /**
   * Determines whether this is running in a DocuSign for Salesforce iFrame.
   * @returns {boolean} True if this is running in our iFrame, false otherwise.
   */
  var isInIFrame = function () {
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

  /**
   * Navigates to a Salesforce object.
   * @param id {string} The ID of the target object.
   * @param pathPrefix {string} The path prefix, if any.
   */
  var navigateToSObject = function (id, pathPrefix) {
    if (isInIFrame()) {
      window.parent.navUtils.navigateToSObject(id, pathPrefix);
    } else if (_isLightningOrMobile()) {
      sforce.one.navigateToSObject(id);
    } else {
      window.location.href = (pathPrefix) ? pathPrefix + '/' + id : '/' + id;
    }
  };

  /**
   * Fires a URL navigation event.
   * @param url {string} The URL to navigate to.
   */
  var navigateToUrl = function (url) {
    var navEvt = $A.get('e.force:navigateToURL');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'url': url
      });
      navEvt.fire();
    }
  };

  return Object.freeze({
    isInIFrame: isInIFrame,
    navigateToSObject: navigateToSObject,
    navigateToUrl: navigateToUrl,
    isLightningOrMobile: _isLightningOrMobile,
  });
}());
