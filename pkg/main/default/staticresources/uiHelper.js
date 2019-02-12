window.UIHelper = function (uiEventHandler, loadingEventName, toastEventName) {

  var _eventHandler = uiEventHandler;
  var _loadingEventName = loadingEventName ? loadingEventName : 'loadingEvent';
  var _toastEventName = toastEventName ? toastEventName : 'toastEvent';

  var _setLoading = function (isLoading) {
    var evt = _eventHandler ? _eventHandler.getEvent(_loadingEventName) : null;
    if (evt) {
      evt.setParams({
        isLoading: isLoading === true
      });
      evt.fire();
    }
  };

  var _showToast = function (message, mode) {
    var evt = _eventHandler ? _eventHandler.getEvent(_toastEventName) : null;
    if (evt) {
      evt.setParams({
        show: true, message: message, mode: mode
      });
      evt.fire();
    }
  };

  var _hideToast = function () {
    var evt = _eventHandler ? _eventHandler.getEvent(_toastEventName) : null;
    if (evt) {
      evt.setParams({
        show: false
      });
      evt.fire();
    }
  };

  var _invokeAction = function (action, params, callback) {
    _setLoading(true);
    if (uiEventHandler && action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          callback(response.getReturnValue());
        } else {
          var errors = response.getError();
          var message = errors;
          if (Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
          }
          _showToast(message, 'error');
        }
        _setLoading(false);
      });
      $A.enqueueAction(action);
    }
  };

  return {
    setLoading: _setLoading,
    showToast: _showToast,
    hideToast: _hideToast,
    invokeAction: _invokeAction
  };
};
