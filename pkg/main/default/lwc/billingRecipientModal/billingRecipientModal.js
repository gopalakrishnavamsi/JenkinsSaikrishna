import {LightningElement, api} from 'lwc';
import {formatLabels,isEmpty} from 'c/utils';
import SelectedRecipientsOfTotalRecipients from '@salesforce/label/c.SelectedRecipientsOfTotalRecipients';
import DecRecordFields from '@salesforce/label/c.DecRecordFields';
import AddRecipient from '@salesforce/label/c.AddRecipient';
import ToLabel from '@salesforce/label/c.ToLabel';
import TabNameandEmail from '@salesforce/label/c.TabNameandEmail';
import AddAndNew from '@salesforce/label/c.AddAndNew';
import Add from '@salesforce/label/c.Add';
import Cancel from '@salesforce/label/c.Cancel';

export default class BillingRecipientsModal extends LightningElement {

  label = {
    SelectedRecipientsOfTotalRecipients,
    DecRecordFields,
    AddRecipient,
    ToLabel,
    TabNameandEmail,
    AddAndNew,
    Add,
    Cancel
  };

  emailRegEx = /^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$/;

  SelectedRecipientsOfTotalRecipients = this.label.SelectedRecipientsOfTotalRecipients;
  defaultType = this.label.DecRecordFields;
  selectedItem;
  getRecipientItem;
  isValid = false;
  index;
  recipientData = [];
  isEdit = false;

  @api isOpen;
  @api handleClose;
  @api selectedRecipients;
  @api sourceRecipientData;

  get isSaveDisabled() {
    return !(this.isValid && ((this.selectedRecipients.length < 5) || this.isEdit));
  }

  get selectedOfTotalFilesLabel() {
    return formatLabels(this.SelectedRecipientsOfTotalRecipients, this.selectedRecipients.length, 5);
  }

  get isRelatedFields() {
    return this.defaultType == this.label.DecRecordFields;
  }

  get isNameAndEmail(){
    return this.defaultType == this.label.TabNameandEmail;
  }

  closeModal = () => {
    this.handleClose();
  };

  //disabling Add & Add and New Buttons based on isValid variable
  disableSave(){
    this.isValid = false;
  }

  //change recipient type selection
  handleChange(event){
   if (this.defaultType === event.detail.name) return;
    this.defaultType = event.detail.name;
    this.isValid = false;
    this.getRecipientItem = '';
  };

  //intake slected value from Record fields
  handleSelect = ({detail}) => {
    this.isValid = !isEmpty(detail) ? true : false;
    this.selectedItem = JSON.parse(JSON.stringify(detail));
    this.selectedItem.scope= this.label.DecRecordFields;
    this.selectedItem.variant=this.label.ToLabel;
  }

  //intake inputs from Name and email type
  inputChange = ({detail}) => {
    this.isValid = !isEmpty(detail.name) ? true : false;
    this.selectedItem = detail;
  }

  //Add button
  saveRecipient = () => {
      this.saveData('saverecipient');
  };

  //Add and New button
  SaveAndNew = () => {
    this.saveData('saveandnew');
    this.isEdit = false;
  };

  //saving data after validating inputs
  saveData(type) {
    this.isValid = false;
      if((this.defaultType == this.label.TabNameandEmail && this.emailRegEx.test(this.selectedItem.name.toLowerCase())) || this.defaultType == this.label.DecRecordFields) {
        this.handleClose();
        this.isEdit ? (this.recipientData[this.index] = this.selectedItem) : this.recipientData.push(this.selectedItem);
        this.dispatchEvent(new CustomEvent(type, {detail: this.selectedItem}));
        if(type = 'saveandnew') {
          (this.defaultType == 'Record Fields') ? this.template.querySelector('c-billing-record-field').saveAndNew() : this.template.querySelector('c-billing-custom-recipient').saveAndNew();
        }
      } else {
        this.template.querySelector('c-billing-custom-recipient').isInvalidEmail();
      }
  }

  //open modal withedit mode 
  @api
  editMode(index) {
    this.getRecipientItem =this.selectedRecipients[index];
    this.defaultType = this.selectedRecipients[index].scope;
    this.isEdit = true;
    this.isValid = true;
    this.index = index;
    return;
  }

  //open modal by resetting
  @api
  reset() {
    this.getRecipientItem = '';
    this.isEdit = false;
    return;
  }

  //After delete action, assigning updated list to recipientData
  @api
  deleteField(selectedRecipient) {
    return this.recipientData = selectedRecipient;
  }

}