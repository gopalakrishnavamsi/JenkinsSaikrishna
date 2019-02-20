({
    handleRecipientIdChange: function (component, event, helper) {
        var r = component.get('v.recipient');
        var sId = component.get('v.sourceId');
        ///raise event

        if (r && sId && (!r.source || (r.source.id !== sId))) {
          var e = component.getEvent('recipientIdChange');
          r.source = {
            id: sId
          };
          e.setParams({data: r});
          e.fire();
        }
    }
})