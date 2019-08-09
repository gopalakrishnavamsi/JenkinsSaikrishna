({
  updateUI: function (component, event) {
    var title = event.getParam('title');
    var summary = event.getParam('summary');
    var index = event.getParam('index');
    var body = event.getParam('body');
    var type = event.getParam('type');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    if (toComponent === 'CLMCardModel' && fromComponent !== 'CLMCardModel') {
      if (type === 'update') {
        if (title !== undefined) {
          component.set('v.title', title);
        }
        if (summary !== undefined) {
          component.set('v.summary', summary);
        }
        if (index !== undefined) {
          component.set('v.index', index);
        }
        if (body !== undefined) {
          component.set('v.body', body);
        }
      }
    }
  },
});