import {LightningElement, api} from 'lwc';
import {
  handleDragEnter,
  handleDragOver,
  handleDragLeave,
  addDragOverStyle,
  removeDragOverStyle,
  handleDrop,
  itemDragStart,
  itemDragEnd
} from 'c/dragUtils';

export default class DecRecipientsList extends LightningElement {

  @api
  recipients = [];

  fromIndex = null;

  handleDragEnter(evt) {
    handleDragEnter(this, evt);
  }

  handleDragOver(evt) {
    handleDragOver(this, evt);
  }

  handleDragLeave(evt) {
    handleDragLeave(this, evt);
  }

  addDragOverStyle(index) {
    addDragOverStyle(this, index);
  }

  removeDragOverStyle(index) {
    removeDragOverStyle(this, index);
  }

  itemDragStart(evt) {
    itemDragStart(this, evt.currentTarget.dataset.id);
  }

  itemDragEnd(evt) {
    itemDragEnd(this, evt.currentTarget.dataset.id);
  }

  handleDrop(evt) {
    handleDrop(this, evt, this.updateRecipients.bind(this));
  }

  /** Recipient-specific functions for envelope configuration **/

  updateRecipients(recipients) {
    this.dispatchEvent(new CustomEvent('updaterecipient', {
      detail: {
        recipients
      },
      bubbles: true
    }));
  }
}