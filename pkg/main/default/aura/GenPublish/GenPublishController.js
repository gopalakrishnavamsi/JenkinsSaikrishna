({
  validate: function (component, event, helper) {
    return new Promise($A.getCallback(function (resolve, reject) {
      resolve();
    }));
  }
});