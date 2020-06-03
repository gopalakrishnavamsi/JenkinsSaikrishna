import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  privateRecipients = [];

  @api
  get recipients() {
    return this.privateRecipients;
  }

  set recipients(value) {
    this.privateRecipients = !isEmpty(value) ? JSON.parse(value) : [];
  }


  @api
  sourceObject;

  recipientsJson;

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  addRecipient = (recipient) => {
    recipient.routingOrder = this.recipients.length + 1;
    this.privateRecipients.push(recipient);
    this.recipientsJson = JSON.stringify(this.privateRecipients);
    this.closeRecipientsModal();
  };


  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };

}