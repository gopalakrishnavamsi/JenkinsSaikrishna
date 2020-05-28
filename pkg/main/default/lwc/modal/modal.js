import { LightningElement, api } from 'lwc';

// utility functions
import { isEmpty } from 'c/utils';

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
    set header(value) {
        this.hasHeaderString = !isEmpty(value);
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
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

    handleKeyPress({ code }) {
        if (code === 'Escape') {
            this.handleCloseModal();
        }
    }

    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
