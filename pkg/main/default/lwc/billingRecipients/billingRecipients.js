import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';
import getRecipientsData from '@salesforce/apex/GenBillingService.getRecipientsData';
import DecRecordFields from '@salesforce/label/c.DecRecordFields';
import ToLabel from '@salesforce/label/c.ToLabel';
import AddRecipient from '@salesforce/label/c.AddRecipient';
import Recipients from '@salesforce/label/c.Recipients';

export default class BillingRecipients extends LightningElement {

  label = {
    DecRecordFields,
    ToLabel,
    AddRecipient,
    Recipients
  };

  selectedRecipients = [];
  index;
  isEdit;
  showRecipientModal;
  //show spinner
  isLoading = false;

  sourceRecipientData = [];
  @api scope;
  @api config = [];
 
  connectedCallback() {
  this.isLoading = true;
  if(this.config.length > 0) {
      this.selectedRecipients = [...this.config];
    }
    getRecipientsData()
        .then(result => {
          this.sourceRecipientData = [...result];
          if(this.config.length  == 0) this.setDefaultRecipient();
          this.isLoading = false;
        })
        .catch(error => { 
          //TODO
        });
  }

  //set default recipient on init
  setDefaultRecipient() {
    for  (const recipient  of this.sourceRecipientData) {
      if(recipient.name == "blng__Order__r.BillToContact.email") {
        recipient.variant = this.label.ToLabel;
        recipient.scope = this.label.DecRecordFields;
        this.selectedRecipients.push(recipient);
        break;
      }
    }
    this.sendRecipients();
  }

  get limitReached() {
    return this.selectedRecipients.length > 4;
  }

  handleOpen = () => {
    this.isEdit = false;
    this.showRecipientModal = true;
    this.template.querySelector('c-billing-recipient-modal').reset();
  };

  closeModal = () => {
    this.showRecipientModal = false;
  };

  saveRecipient = ({detail}) => {
    this.isEdit ? this.selectedRecipients[this.index] = detail : this.selectedRecipients.push(detail);
    this.sendRecipients();
  }

  get hasRecipients() {
    return !isEmpty(this.selectedRecipients);
  }

  saveAndNew = ({detail}) => {
    this.showRecipientModal = true;
    if (this.isEdit) {
      this.isEdit = false;
      this.selectedRecipients[this.index] = detail;
    } else {
    this.selectedRecipients.push(detail);
    }
    this.sendRecipients();
  }

  //delete recipient
  handleDelete = ({detail}) => {
    this.selectedRecipients = this.selectedRecipients.filter(function(item,index) {
      return index !== detail;
    });
    this.template.querySelector('c-billing-recipient-modal').deleteField(this.selectedRecipients);
    this.sendRecipients();
  }

  //Pass Updated list to Parent GenBilling component
  sendRecipients() {
    let recipientslist = this.selectedRecipients;
    this.dispatchEvent(new CustomEvent('saverecipient', {detail: {recipientslist}}));
  }

  //Edit recipient
  handleEdit = ({detail}) => {
    this.isEdit = true;
    this.index = detail;
    this.showRecipientModal = true;
    this.template.querySelector('c-billing-recipient-modal').editMode(detail);
  }

}