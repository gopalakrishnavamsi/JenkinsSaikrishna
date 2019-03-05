/**
 *
 * @param eventSource
 * @param loadingEventName
 * @param toastEventName
 * @returns {Readonly<{hideToast: hideToast, invokeAction: invokeAction, setLoading: setLoading, showToast: showToast, ToastMode: {SUCCESS: string, ERROR: string, WARNING: string}, getErrorMessage: (function(*=): string)}>}
 * @constructor
 */
window.UIHelper = function (eventSource, loadingEventName, toastEventName) {
  /**
   * The event source Lightning component.
   * @private
   */
  var _eventSource = eventSource;
  /**
   * The name of the loading event. Defaults to 'loadingEvent'.
   * @private
   */
  var _loadingEventName = loadingEventName ? loadingEventName : 'loadingEvent';
  /**
   * The name of the toast event. Defaults to 'toastEvent'.
   * @private
   */
  var _toastEventName = toastEventName ? toastEventName : 'toastEvent';

  /**
   * Fires a component loading event.
   * @param isLoading {boolean} Whether or not the component is in a loading state.
   */
  var setLoading = function (isLoading) {
    var event = _eventSource ? _eventSource.getEvent(_loadingEventName) : null;
    if (event) {
      event.setParams({
        isLoading: isLoading === true
      });
      event.fire();
    }
  };

  /**
   * Enumeration of possible toast notification display modes.
   * @type {{SUCCESS: string, ERROR: string, WARNING: string}}
   */
  var toastMode = Object.freeze({
    SUCCESS: 'success',
    WARNING: 'warning',
    ERROR: 'error'
  });

  /**
   * Displays a toast notification.
   * @param message {string} The message to display.
   * @param mode {_toastMode} The mode of the toast notification.
   */
  var showToast = function (message, mode) {
    var event = _eventSource ? _eventSource.getEvent(_toastEventName) : null;
    if (event) {
      event.setParams({
        show: true, message: message, mode: mode
      });
      event.fire();
    }
  };

  var hideToast = function () {
    var event = _eventSource ? _eventSource.getEvent(_toastEventName) : null;
    if (event) {
      event.setParams({
        show: false
      });
      event.fire();
    }
  };

  /**
   *
   * @param response {Response}
   * @returns {string}
   */
  var getErrorMessage = function (response) {
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

  /**
   *
   * @param action {Action}
   * @param params {object}
   * @param onSuccess {function}
   * @param onError {function}
   * @param onComplete {function}
   */
  var invokeAction = function (action, params, onSuccess, onError, onComplete) {
    hideToast();
    setLoading(true);
    if (action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          if (onSuccess) onSuccess(response.getReturnValue());
        } else {
          showToast(getErrorMessage(response), 'error');
          if (onError) onError(response.getError());
        }
        setLoading(false);
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  };

  return Object.freeze({
    ToastMode: toastMode,
    setLoading: setLoading,
    showToast: showToast,
    hideToast: hideToast,
    getErrorMessage: getErrorMessage,
    invokeAction: invokeAction
  });
};
