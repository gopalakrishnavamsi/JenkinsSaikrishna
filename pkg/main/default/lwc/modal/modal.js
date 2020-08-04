import {LightningElement, api} from 'lwc';

// utility functions
import {isEmpty} from 'c/utils';

const MODAL_ON_MODAL_STYLE = 'ds-modal-on-modal';
const BASE_MODAL_CLASS = 'slds-modal slds-fade-in-open ';
const SMALL_MODAL_CLASS = BASE_MODAL_CLASS + 'slds-modal_small';
const MEDIUM_MODAL_CLASS = BASE_MODAL_CLASS + 'slds-modal_medium';
const LARGE_MODAL_CLASS = BASE_MODAL_CLASS + 'slds-modal_large';

const MODAL_SIZE_TO_CLASS = {
  small: SMALL_MODAL_CLASS,
  medium: MEDIUM_MODAL_CLASS,
  large: LARGE_MODAL_CLASS
};

/**
 * Props to pass in from parent:
 * @param {string} header - title of the modal
 * @param {boolean} showModal - flag that determines whether to show the modal
 * @param {function} onclose - event that is called when closing the modal
 */

/**
 * Slots:
 * header - available when non-empty header prop is not passed in
 * content - main body of modal
 * footer - footer content which usually contains buttons for the modal
 */

export default class Modal extends LightningElement {
  hasHeaderString = false;
  _headerPrivate;

  @api
  showModal = false;
  @api
  modalSize;
  @api
  modalOnModal;

  @api
  set header(value) {
    this.hasHeaderString = !isEmpty(value);
    this._headerPrivate = value;
  }

  get header() {
    return this._headerPrivate;
  }

  get modalClass() {
    return !isEmpty(this.modalOnModal) ? LARGE_MODAL_CLASS + ' ' + MODAL_ON_MODAL_STYLE :
      !isEmpty(this.modalSize) ? MODAL_SIZE_TO_CLASS[this.modalSize] : BASE_MODAL_CLASS;
  }

  connectedCallback() {
    this.addEventListener('mouseenter', this.focusElement.bind(this));
    this.addEventListener('keyup', this.handleKeyPress.bind(this));
  }

  disconnectedCallback() {
    this.removeEventListener('mouseenter', this.focusElement.bind(this));
    this.removeEventListener('keyup', this.handleKeyPress.bind(this));
  }

  focusElement() {
    // auto-focus upon opening modal to allow closing via ESC key
    this.template.querySelector('section').focus();
  }

  handleKeyPress({code}) {
    if (code === 'Escape') {
      this.handleCloseModal();
    }
  }

  handleCloseModal() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}
