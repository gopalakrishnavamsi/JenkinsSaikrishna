window.UIHelper = function (eventSource, loadingEventName, toastEventName) {

  var _eventSource = eventSource;
  var _loadingEventName = loadingEventName ? loadingEventName : 'loadingEvent';
  var _toastEventName = toastEventName ? toastEventName : 'toastEvent';

  var _setLoading = function (isLoading) {
    var event = _eventSource ? _eventSource.getEvent(_loadingEventName) : null;
    if (event) {
      event.setParams({
        isLoading: isLoading === true
      });
      event.fire();
    }
  };

  var _showToast = function (message, mode) {
    var event = _eventSource ? _eventSource.getEvent(_toastEventName) : null;
    if (event) {
      event.setParams({
        show: true, message: message, mode: mode
      });
      event.fire();
    }
  };

  var _hideToast = function () {
    var event = _eventSource ? _eventSource.getEvent(_toastEventName) : null;
    if (event) {
      event.setParams({
        show: false
      });
      event.fire();
    }
  };

  var _getErrorMessage = function (response) {
    var message = '';
    if (response) {
      var errors = response.getError();
      message = errors;
      if (Array.isArray(errors) && errors.length > 0) {
        message = errors[0].message;
      }
    }
    return message;
  };

  var _invokeAction = function (action, params, onSuccess, onError, onComplete) {
    _hideToast();
    _setLoading(true);
    if (action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          if (onSuccess) onSuccess(response.getReturnValue());
        } else {
          _showToast(_getErrorMessage(response), 'error');
          if (onError) onError(response.getError());
        }
        _setLoading(false);
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  };

  return {
    setLoading: _setLoading,
    showToast: _showToast,
    hideToast: _hideToast,
    getErrorMessage: _getErrorMessage,
    invokeAction: _invokeAction
  };
};
