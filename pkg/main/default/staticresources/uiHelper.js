/**
 *
 * @param loadingEvent {function<object>}
 * @param toastEvent {function<object>}
 * @returns {Readonly<{hideToast: hideToast, invokeAction: invokeAction, setLoading: setLoading, showToast: showToast, ToastMode: {SUCCESS: string, ERROR: string, WARNING: string}, getErrorMessage: (function(Response): string)}>}
 * @constructor
 */
window.UIHelper = function (loadingEvent, toastEvent) {
  /**
   * Fires a component loading event.
   * @param isLoading {boolean} Whether or not the component is in a loading state.
   */
  var setLoading = function (isLoading) {
    var event = loadingEvent();
    if (event && event.setParams && event.fire) {
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
  var ToastMode = Object.freeze({
    SUCCESS: 'success', WARNING: 'warning', ERROR: 'error'
  });

  /**
   * Displays a toast notification.
   * @param message {string} The message to display.
   * @param mode {ToastMode} The mode of the toast notification.
   */
  var showToast = function (message, mode) {
    var event = toastEvent();
    if (event && event.setParams && event.fire) {
      event.setParams({
        show: true, message: message, mode: mode
      });
      event.fire();
    }
  };

  /**
   * Hides a toast notification.
   */
  var hideToast = function () {
    var event = toastEvent();
    if (event && event.setParams) {
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
      if (!$A.util.isEmpty(errors)) {
        message = errors[0].message;
      }
    }
    return message;
  };

  /**
   *
   * @param action {object}
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
          showToast(getErrorMessage(response), ToastMode.ERROR);
          if (onError) onError(response.getError());
        }
        setLoading(false);
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  };

  return Object.freeze({
    ToastMode: ToastMode,
    setLoading: setLoading,
    showToast: showToast,
    hideToast: hideToast,
    getErrorMessage: getErrorMessage,
    invokeAction: invokeAction
  });
};
