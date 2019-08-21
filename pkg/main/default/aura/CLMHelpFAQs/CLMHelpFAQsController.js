({
  toggleSection: function (component,event) {
    var label = event.currentTarget.id;
    var acc = component.find(label);
    for (var cmp in acc) {
      $A.util.toggleClass(acc[cmp], 'slds-show');
      $A.util.toggleClass(acc[cmp], 'slds-hide');
    }
  },
});