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

const DEFAULT_ROUTING_ORDER = 1;
import {genericEvent, getRandomKey} from 'c/utils';

export default class DecRecipientsList extends LightningElement {

  privateRecipients = [];

  @api
  get list() {
    return this.privateRecipients;
  }

  get key() {
    return getRandomKey();
  }

  set list(val) {
    this.privateRecipients = val;
  }

  @api
  isSigningOrder = false;

  fromIndex = 0;

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
    if (!this.isSigningOrder) {
      this.isSigningOrder = true;
      this.privateRecipients = this.privateRecipients.map((r, index) => ({
        ...r,
        routingOrder: this.isSigningOrder ? index + 1 : DEFAULT_ROUTING_ORDER
      }));
    }
  }

  itemDragEnd(evt) {
    itemDragEnd(this, evt.currentTarget.dataset.id);
  }

  handleDrop(evt) {
    handleDrop(this, evt, this.updateRecipients.bind(this));
  }

  /** Recipient-specific functions for envelope configuration **/

  updateRecipients = (recipients) => {
    this.dispatchEvent(new CustomEvent('updaterecipient', {
      detail: {
        recipients
      },
      bubbles: true
    }));
  };

  handleRoutingOrderUpdate = (event) => {
    let data = event.detail.data;
    this.privateRecipients = this.privateRecipients.map((r, index) => ({
      ...r,
      routingOrder: index === data.currentIndex ? data.newRoutingOrder : r.routingOrder
    }));
    genericEvent('updaterecipient', this.privateRecipients, this, false);
  };
}