({
  onShow: function (component) {
    $A.util.removeClass(component.find('ds-spinner'), 'slds-hide');
  },

  onHide: function (component) {
    $A.util.addClass(component.find('ds-spinner'), 'slds-hide');
  }
});