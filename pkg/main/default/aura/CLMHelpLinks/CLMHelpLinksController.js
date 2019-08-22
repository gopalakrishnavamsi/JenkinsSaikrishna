({
  navigation: function (component, event, helper) {
    var buttonClicked = event.getSource().getLocalId();
    if (buttonClicked === 'getSupportBtn') {
      helper.goToUrl(component, $A.get('$Label.c.GetSupportURL'));
    } else if (buttonClicked === 'learnMoreBtn') {
      helper.goToUrl(component, $A.get('$Label.c.LearnMoreURL'));
    } else if (buttonClicked === 'checkStatusBtn') {
      helper.goToUrl(component, $A.get('$Label.c.CheckStatusURL'));
    } else if (buttonClicked === 'getTrainingBtn') {
      helper.goToUrl(component, $A.get('$Label.c.GetTrainingURL'));
    } else if (buttonClicked === 'visitCommunityBtn') {
      helper.goToUrl(component, $A.get('$Label.c.VisitCommunityURL'));
    } else if (buttonClicked === 'viewResourcesBtn') {
      helper.goToUrl(component, $A.get('$Label.c.ViewResourcesURL'));
    }
  },

  gotoFAQs: function (component, event, helper) {
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMHelpLinks',
      toComponent: 'CLMHelpLayout',
      type: 'navigation',
      data: { value: 'faqs' }
    }, 'CLMEvent');
  }
})