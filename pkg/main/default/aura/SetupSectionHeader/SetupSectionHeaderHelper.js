({
  initializeComponent: function (component) {
    if (component.get('v.showTrialBar') === true) {
      component.set('v.trialMessage', stringUtils.format($A.get('$Label.c.TrialExpirationMessage'), component.get('v.trialProductName')));
    }
  }
});