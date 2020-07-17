import {LightningElement, api} from 'lwc';
import {Labels, Recipient, StandardEvents} from 'c/recipientUtils';
import {
  isEmpty,
  proxify,
  removeArrayElement,
  subscribeToMessageChannel,
  editArrayElement,
  groupBy,
  genericEvent
} from 'c/utils';
import {createMessageContext, releaseMessageContext} from 'lightning/messageService';
import decTemplate from './decRecipients.html';
import sendingTemplate from './sendingRecipients.html';

const DEFAULT_ROUTING_ORDER = 1;

export default class Recipients extends LightningElement {

  @api isSending;

  @api readOnly;

  Labels = Labels;

  showAddRecipientsModal = false;

  privateRecipients = proxify([]);

  editRecipientIndex = null;

  isSigningOrder = false;

  isDirtyRecipients = false;

  isEmptyRecipients = false;

  @api
  sourceObject;

  context = createMessageContext();

  @api
  get recipients() {
    return this.privateRecipients;
  }

  set recipients(val) {
    this.privateRecipients = proxify(!isEmpty(val) ? val.map(r => Recipient.fromObject({
      ...r,
      isPlaceHolder: r.isPlaceHolder
    })) : []);
    this.isEmptyRecipients = isEmpty(this.privateRecipients) || (!isEmpty(this.privateRecipients) && this.privateRecipients.length === 0);
    genericEvent.call(this, 'emptyrecipients', this.isEmptyRecipients, false);
  }

  connectedCallback() {
    this.deleteChannelEvent = subscribeToMessageChannel(
      this.context,
      this.deleteChannelEvent,
      StandardEvents.Delete,
      this.handleDeleteRecipient
    );

    this.editChannelEvent = subscribeToMessageChannel(
      this.context,
      this.editChannelEvent,
      StandardEvents.Edit,
      this.handleEditRecipient
    );

    if (!isEmpty(this.recipients)) {
      let recipientsGroup = groupBy(this.recipients, 'routingOrder');
      Object.keys(recipientsGroup).forEach(function (key) {
        if (parseInt(key) > DEFAULT_ROUTING_ORDER) {
          this.isSigningOrder = true;
        }
      }, this);
    }
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @api
  fetchRecipients() {
    return {'data': this.privateRecipients, 'isDirtyRecipients': this.isDirtyRecipients};
  }

  get signingOrderButtonIcon() {
    return this.isSigningOrder ? 'utility:check' : 'utility:add';
  }

  get hasRecipients() {
    return !isEmpty(this.privateRecipients) && this.privateRecipients.length > 0;
  }

  get editRecipient() {
    return isEmpty(this.editRecipientIndex) ? null : this.recipients[this.editRecipientIndex];
  }

  set editRecipient(val) {
    this.recipients = editArrayElement(this.recipients, this.editRecipientIndex, val);
  }

  get isPlaceHolder() {
    return !isEmpty(this.editRecipient) && this.editRecipient.isPlaceHolder;
  }

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
    if (!isEmpty(this.editRecipientIndex)) this.editRecipientIndex = null;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  removeRecipient = (index) => {
    this.isDirtyRecipients = true;
    this.recipients = removeArrayElement(this.recipients, index);
  };

  addRecipient = (recipient, isAddNew = false) => {
    this.isDirtyRecipients = true;
    const isEdit = !isEmpty(this.editRecipientIndex);

    if (this.isSigningOrder && !isEdit) {
      const maxRoutingOrder = Math.max(...this.recipients.map(r => r.routingOrder), 0);
      recipient.routingOrder = maxRoutingOrder + 1;
    } else if (!isEdit) recipient.routingOrder = DEFAULT_ROUTING_ORDER;

    if (isEdit) {
      this.editRecipient = recipient;
      this.editRecipientIndex = null;
    } else this.recipients = [...this.recipients, recipient];

    this.closeRecipientsModal();
    if (isAddNew) this.handleRecipientsModalOpen();
  };

  handleDeleteRecipient = ({index}) => {
    this.isDirtyRecipients = true;
    if (isEmpty(index) || isEmpty(this.recipients) || isEmpty(this.recipients[index])) return;
    this.recipients = removeArrayElement(this.recipients, index);
  };

  handleEditRecipient = ({index}) => {
    this.editRecipientIndex = index;
    this.showAddRecipientsModal = true;
  };

  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };

  handleRecipientSigningOrder = () => {
    this.isDirtyRecipients = true;
    this.isSigningOrder = !this.isSigningOrder;
    this.recipients = this.recipients.map((r, index) => ({
      ...r,
      routingOrder: this.isSigningOrder ? index + 1 : DEFAULT_ROUTING_ORDER
    }));
  };

  handleRecipientsUpdate = (event) => {
    this.isDirtyRecipients = true;
    if (event.detail.data) {
      this.recipients = event.detail.data.sort(function (x, y) {
        return x.routingOrder - y.routingOrder;
      });
    }
  };

  handleDragRecipientsUpdate = (event) => {
    this.isDirtyRecipients = true;
    if (event.detail.data) {
      this.recipients = event.detail.data;
    }
  };

  render() {
    return this.isSending ? sendingTemplate : decTemplate;
  }
}