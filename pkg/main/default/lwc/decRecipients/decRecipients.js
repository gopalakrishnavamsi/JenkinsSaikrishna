import {LightningElement, api} from 'lwc';
import {Labels, Recipient} from 'c/recipientUtils';
import {groupBy, isEmpty, proxify} from 'c/utils';

const DEFAULT_ROUTING_ORDER = 1;

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  @api
  recipients = [];

  privateRecipients = proxify([]);

  isSigningOrder = false;

  @api
  sourceObject;

  connectedCallback() {
    if (!isEmpty(this.recipients)) {
      this.privateRecipients = this.recipients.map(r => Recipient.fromObject(r));
      let recipientsGroup = groupBy(this.privateRecipients, 'routingOrder');
      Object.keys(recipientsGroup).forEach(function (key) {
        if (parseInt(key) > DEFAULT_ROUTING_ORDER) {
          this.isSigningOrder = true;
        }
      }, this);
    }
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

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  addRecipient = (recipient, isAddNew = false) => {
    if (this.isSigningOrder) {
      const maxRoutingOrder = Math.max(...this.privateRecipients.map(r => r.routingOrder), 0);
      recipient.routingOrder = maxRoutingOrder + 1;
    } else {
      recipient.routingOrder = DEFAULT_ROUTING_ORDER;
    }
    this.privateRecipients = [...this.privateRecipients, recipient];
    this.closeRecipientsModal();
    if (isAddNew) {
      this.handleRecipientsModalOpen();
    }
  };

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