({
  onInitializeComponent: function (component) {
    component.set('v.docGenFeatures', [$A.get('$Label.c.GenerateWordOrPdfFeature'), $A.get('$Label.c.MergeDataFeature'), $A.get('$Label.c.ConditionalContentFeature'), $A.get('$Label.c.DynamicPricingFeature'), $A.get('$Label.c.ESignatureCompatibleFeature')]);
    component.set('v.negotiateFeatures', [$A.get('$Label.c.ApproversFeature'), $A.get('$Label.c.ExternalReviewFeature'), $A.get('$Label.c.VersionControlFeature'), $A.get('$Label.c.RoutingFeature')]);
  },

  toggleGenFeaturesSection: function (component) {
    component.set('v.docGenFeaturesExpanded', !component.get('v.docGenFeaturesExpanded'));
  },

  toggleNegotiateFeaturesSection: function (component) {
    component.set('v.negotiateFeaturesExpanded', !component.get('v.negotiateFeaturesExpanded'));
  }
});