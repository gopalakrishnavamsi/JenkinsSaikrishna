import {LightningElement, api} from 'lwc';
import {Labels, Recipient} from 'c/recipientUtils';
import {isEmpty, proxify} from 'c/utils';

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  @api
  recipients = [];

  privateRecipients = proxify([]);

  @api
  sourceObject;

  connectedCallback() {
    if (!isEmpty(this.recipients)) {
      this.privateRecipients = this.recipients.map(r => Recipient.fromObject(r));
    }
  }

  @api
  fetchRecipients = () => {
    return this.privateRecipients;
  };

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
    recipient.routingOrder = this.privateRecipients.length + 1;
    this.privateRecipients = [...this.privateRecipients, recipient];
    this.closeRecipientsModal();
    if(isAddNew){
      this.handleRecipientsModalOpen();
    }
  };

  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };
}