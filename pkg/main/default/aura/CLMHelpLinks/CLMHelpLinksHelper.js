({
  goToUrl: function (component, url) {
    var redirectUrl = $A.get('e.force:navigateToURL');
    redirectUrl.setParams({
      'url': url
    });
    redirectUrl.fire();
  }
})