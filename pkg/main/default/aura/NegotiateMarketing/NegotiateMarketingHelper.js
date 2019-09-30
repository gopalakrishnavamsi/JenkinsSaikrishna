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
  },

  showGenTrialModal: function (component) {
    $A.createComponent('c:StartProductTrial',
      {
        modalTitle: $A.get('$Label.c.TryDocuSignGen'),
        showModal: true,
        startGenTrial: true
      },
      $A.getCallback(function (componentBody) {
          if (component.isValid()) {
            var targetCmp = component.find('startProductTrialModal');
            var body = targetCmp.get('v.body');
            targetCmp.set('v.body', []);
            body.push(componentBody);
            targetCmp.set('v.body', body);
          }
        }
      ));
  },

  showNegotiateTrialModal: function (component) {
    $A.createComponent('c:StartProductTrial',
      {
        modalTitle: $A.get('$Label.c.TryDocuSignNegotiate'),
        showModal: true,
        startNegotiateTrial: true
      },
      $A.getCallback(function (componentBody) {
          if (component.isValid()) {
            var targetCmp = component.find('startProductTrialModal');
            var body = targetCmp.get('v.body');
            targetCmp.set('v.body', []);
            body.push(componentBody);
            targetCmp.set('v.body', body);
          }
        }
      ));
  }
});