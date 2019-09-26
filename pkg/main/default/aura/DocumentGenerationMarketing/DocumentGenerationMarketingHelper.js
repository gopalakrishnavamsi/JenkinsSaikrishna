({
  toggleGenFeaturesSection: function (component) {
    component.set('v.docGenFeaturesExpanded', !component.get('v.docGenFeaturesExpanded'));
  },

  toggleNegotiateFeaturesSection: function (component) {
    component.set('v.negotiateFeaturesExpanded', !component.get('v.negotiateFeaturesExpanded'));
  }
});