({
  onInit: function(component, event, helper) {
    var onLoad = component.get('v.onLoad');
    onLoad()
    .then(function(documentUrl) {
      component.set('v.documentUrl', documentUrl);
    })
    .catch(function(err) {
      helper.showToast(component, err, 'error');
    });
  },

  copyButtonClicked: function(component, event, helper) {
    helper.copyToClipboard(component);
  }
});
