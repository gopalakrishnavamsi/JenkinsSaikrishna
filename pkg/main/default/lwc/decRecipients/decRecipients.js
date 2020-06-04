import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  privateRecipients = [];

  @api
  get recipients() {
    return !isEmpty(this.privateRecipients) ? JSON.stringify(this.privateRecipients) : '';
  }

  set recipients(value) {
    this.privateRecipients = !isEmpty(value) ? JSON.parse(value) : [];
  }

  get hasRecipients() {
    return !isEmpty(this.privateRecipients) && this.privateRecipients.length > 0;
  }

  @api
  fetchRecipients = () => {
    return this.privateRecipients;
  };


  @api
  sourceObject;


  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  addRecipient = (recipient) => {
    recipient.routingOrder = this.privateRecipients.length + 1;
    this.privateRecipients.push(recipient);
    this.closeRecipientsModal();
  };


  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };
}