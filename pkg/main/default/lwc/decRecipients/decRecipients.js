import {LightningElement, api} from 'lwc';
import {Labels, Recipient,StandardEvents} from 'c/recipientUtils';
import {isEmpty,proxify,removeArrayElement,subscribeToMessageChannel,editArrayElement,groupBy} from 'c/utils';
import {createMessageContext,releaseMessageContext} from 'lightning/messageService';

const DEFAULT_ROUTING_ORDER = 1;

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  privateRecipients = proxify([]);

  editRecipientIndex = null;

  isSigningOrder = false;

  @api
  sourceObject;

  context = createMessageContext();

  @api
  get recipients() {
    return this.privateRecipients;
  }

  set recipients(val = []) {
    this.privateRecipients = proxify(val.map(r => Recipient.fromObject(r)))
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
      let recipientsGroup = groupBy(this.privateRecipients, 'routingOrder');
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
  fetchRecipients = () => {
    return this.privateRecipients;
  };

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
    this.recipients = editArrayElement(this.recipients, this.editRecipientIndex, val)
  }

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
    if (!isEmpty(this.editRecipientIndex)) this.editRecipientIndex = null;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  removeRecipient = (index) => {
    this.recipients = removeArrayElement(this.recipients, index);
  }

  addRecipient = (recipient, isAddNew = false) => {
    const isEdit = !isEmpty(this.editRecipientIndex);
    if (this.isSigningOrder && !isEdit) {
      const maxRoutingOrder = Math.max(...this.privateRecipients.map(r => r.routingOrder), 0);
      recipient.routingOrder = maxRoutingOrder + 1;
    } else if (!isEdit) recipient.routingOrder = DEFAULT_ROUTING_ORDER;
    
    if (isEdit) {
      this.editRecipient = recipient; 
      this.editRecipientIndex = null;
    }
    else this.recipients = [...this.privateRecipients, recipient];

    this.closeRecipientsModal();
    if(isAddNew) this.handleRecipientsModalOpen();
  };

  handleDeleteRecipient = ({ index }) => {
    if (isEmpty(index) || isEmpty(this.recipients) || isEmpty(this.recipients[index])) return;
    this.recipients = removeArrayElement(this.recipients, index);
  }

  handleEditRecipient = ({ index }) => {
    this.editRecipientIndex = index;
    this.showAddRecipientsModal = true;
  }

  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };

  handleRecipientSigningOrder = () => {
    this.isSigningOrder = !this.isSigningOrder;
    this.privateRecipients = this.privateRecipients.map((r, index) => ({
      ...r,
      routingOrder: this.isSigningOrder ? index + 1 : DEFAULT_ROUTING_ORDER
    }));
  };

  handleRecipientsUpdate = (event) => {
    if(event.detail.data) {
      this.privateRecipients = event.detail.data.sort(function (x, y) {
        return x.routingOrder - y.routingOrder;
      });
    }
  };

  handleDragRecipientsUpdate = (event) => {
    this.privateRecipients = event.detail.data;
  };
}