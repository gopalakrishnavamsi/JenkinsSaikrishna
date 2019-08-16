({
  handleRecipientIdChange: function (component) {
    var r = component.get('v.recipient');
    var sId = component.get('v.sourceId');

    if (r && sId && (!r.source || (r.source.id !== sId))) {
      var e = component.getEvent('recipientIdChange');
      r.source = {
        id: sId
      };
      e.setParams({data: r});
      e.fire();
    }
  },
  handleSearchValueChange: function (component) {
    component.getEvent('searchTermChange').fire();
  }
});