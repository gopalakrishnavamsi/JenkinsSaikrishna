const UNKNOWN_ICON_NAME = 'doctype:unknown';
const SUCCESS_EVENT_LABEL = 'success';
const ERROR_EVENT_LABEL = 'error';
const UPDATE_EVENT_LABEL = 'update';
const FILE_EXTENSION_TO_ICON_NAME_MAPPING = new Map([
    ['doc' , 'doctype:word'],
    ['docm' , 'doctype:gdoc'],
    ['docx' , 'doctype:word'],
    ['dotm' , 'doctype:gdoc'],
    ['dotx' , 'doctype:gdoc'],
    ['msg' , 'doctype:unknown'],
    ['pdf' , 'doctype:pdf'],
    ['rtf' , 'doctype:gdoc'],
    ['txt' , 'doctype:gdoc'],
    ['wpd' , 'doctype:gdoc'],
    ['xps' , 'doctype:unknown'],
    ['xps' , 'doctype:unknown'],
    ['bmp' , 'doctype:image'],
    ['gif', 'doctype:image'],
    ['jpg' , 'doctype:image'],
    ['jpeg' , 'doctype:image'],
    ['tif' , 'doctype:image'],
    ['png' , 'doctype:image'],
    ['tiff' , 'doctype:image'],
    ['pot'  , 'doctype:slide'],
    ['potx' , 'doctype:slide'],
    ['pps' , 'doctype:slide'],
    ['ppt' , 'doctype:slide'],
    ['pptm' , 'doctype:slide'],
    ['pptx' , 'doctype:slide'],
    ['csv' , 'doctype:csv'],
    ['xls' , 'doctype:gsheet'],
    ['xlsm' , 'doctype:gsheet'],
    ['xlsx' , 'doctype:gsheet'],
    ['xml' , 'doctype:xml'],
    ['' , 'doctype:unknown']]);

const isEmpty = (value) => value === undefined || value === null || value === '';

/**
 * Dispatches a generic custom event
 * @param eventName {string} Name of the event - success, update, error, etc..
 * @param message {string} Data that needs to be passed.
 * @param thisProperty {object} this property of the component that wants to dispatch the event
 * @param isBubbles {boolean} Does event bubble up the chain
 */
const genericEvent = (eventName, message, thisProperty, isBubbles) =>
  thisProperty.dispatchEvent(
    new CustomEvent(eventName, {
      detail: {data: message},
      bubbles: isBubbles ? true : false
    }));

/**
 * Formats a byte size. For example, 2048 bytes will be formatted as '2 kB'.
 * @param size {number} The size in bytes.
 * @param precision {number} Decimal precision [default 2].
 * @returns {string} The formatted size string.
 */
const formatFileSize = (size, precision) => {
  if (!size || typeof size !== 'number' || size < 0) {
    return '0 B';
  }

  let constant = 1024;
  let p = precision || 2;
  let exponents = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  let factor = Math.floor(Math.log(size) / Math.log(constant));

  return parseFloat((size / Math.pow(constant, factor)).toFixed(p)) + ' ' + exponents[factor];
};

/**
 * Formats a string.
 * @param s {string} The format string, e.g. 'Example {0} string {1}'.
 * @param arguments {...*} Replacement arguments.
 * @returns {string} The formatted string.
 */
const format = function (s) {
  if (s) {
    let outerArguments = arguments;
    return s.replace(/{(\d+)}/g, function () {
      return outerArguments[parseInt(arguments[1]) + 1];
    });
  }
  return '';
};

export {
    FILE_EXTENSION_TO_ICON_NAME_MAPPING,
    UNKNOWN_ICON_NAME,
    SUCCESS_EVENT_LABEL,
    ERROR_EVENT_LABEL,
    UPDATE_EVENT_LABEL,
    isEmpty,
    formatFileSize,
    genericEvent,
    format
};