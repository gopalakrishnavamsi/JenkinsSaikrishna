import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecipients extends LightningElement {

  Labels = Labels;

  showAddRecipientsModal = false;

  @api
  recipients = [];

  @api
  sourceObject;

  privateRecipients = [];

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
  };

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  addRecipient = (recipient) => {
    this.privateRecipients.push(recipient);
    this.closeRecipientsModal();
  };
}