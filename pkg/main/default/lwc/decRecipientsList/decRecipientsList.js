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

import {genericEvent, getRandomKey} from 'c/utils';

const DEFAULT_ROUTING_ORDER = 1;

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

  fromRecipientIndex = 0;
  toRecipientIndex = 0;

  handleDragEnter(evt) {
    if (!this.isSigningOrder) {
      genericEvent('signingorderchecked', {}, this, false);
    }
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
    this.fromRecipientIndex = parseInt(evt.currentTarget.dataset.index);
    this.fromIndex = this.fromRecipientIndex;
    itemDragStart(this, evt.currentTarget.dataset.id);
  }

  itemDragEnd(evt) {
    itemDragEnd(this, evt.currentTarget.dataset.id);
  }

  handleDrop(evt) {
    this.toRecipientIndex = parseInt(evt.currentTarget.dataset.index);
    if (this.fromRecipientIndex === this.toRecipientIndex) return;
    handleDrop(this, evt, this.updateRecipients.bind(this));
  }

  updateRecipients = (recipients) => {
    let recs = [...recipients];
    let dragUp = this.toRecipientIndex < this.fromRecipientIndex;
    let updatedRoutingOrder = DEFAULT_ROUTING_ORDER;
    let previousIndexRoutingOrder = recs[this.toRecipientIndex - 1] ? recs[this.toRecipientIndex - 1].routingOrder : 1;
    let nextIndexRoutingOrder = recs[this.toRecipientIndex + 1] ? recs[this.toRecipientIndex + 1].routingOrder : 1;
    if (previousIndexRoutingOrder === nextIndexRoutingOrder || (previousIndexRoutingOrder + 1 === nextIndexRoutingOrder)) {
      updatedRoutingOrder = previousIndexRoutingOrder;
    } else {
      updatedRoutingOrder = dragUp ? (nextIndexRoutingOrder === DEFAULT_ROUTING_ORDER ? DEFAULT_ROUTING_ORDER : nextIndexRoutingOrder - 1) : previousIndexRoutingOrder + 1;
    }

    const updatedRecs = recs.map((r, index) =>
      index === this.toRecipientIndex
        ? {
          ...r,
          routingOrder: updatedRoutingOrder
        }
        : r
    );
    genericEvent('dragrecipientupdate', updatedRecs, this, false);
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