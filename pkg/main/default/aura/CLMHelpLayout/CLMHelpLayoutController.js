({
  showFAQs: function (component, event, helper) {
    component.set('v.showFAQSection', true);
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMHelpLayout',
      toComponent: 'CLMSetupLayout',
      type: 'update',
      tabIndex: '8.1',
    }, 'CLMNavigationEvent');
  },

  goToUrl: function (component, event) {
    var sectionClicked = event.currentTarget.id;
    if (sectionClicked === 'docGenBasics') {
      navUtils.navigateToUrl($A.get('$Label.c.LearnDocGenBasicsURL'));
    } else {
      navUtils.navigateToUrl($A.get('$Label.c.AddCompToLayoutsURL'));
    }
  }
})