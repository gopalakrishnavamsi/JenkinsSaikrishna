({
  buttonClick: function (component) {
    var link = component.get('v.firstButtonNavigation');
    if (link)
      navUtils.navigateToUrl(link);
  }
})
