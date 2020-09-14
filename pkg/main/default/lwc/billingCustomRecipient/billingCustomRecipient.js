import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';
import CustomEmailHelpText from '@salesforce/label/c.CustomEmailHelpText';
import SetasBccCheckbox from '@salesforce/label/c.SetasBccCheckbox';
import InvalidEmailText from '@salesforce/label/c.InvalidEmailText';
import ToLabel from '@salesforce/label/c.ToLabel';
import BccLabel from '@salesforce/label/c.BccLabel';
import NameLabel from '@salesforce/label/c.NameLabel';
import EmailLabel from '@salesforce/label/c.EmailLabel';
import TabNameandEmail from '@salesforce/label/c.TabNameandEmail';
import DuplicateRow from '@salesforce/label/c.DuplicateRow';

export default class BillingNameAndEmail extends LightningElement {
  label = {
    CustomEmailHelpText,
    SetasBccCheckbox,
    InvalidEmailText,
    ToLabel,
    BccLabel,
    NameLabel,
    EmailLabel,
    TabNameandEmail,
    DuplicateRow
  };

  Object ;
  recipientName;
  recipientEmail;
  isBcc;
  errorMsg;
  isError = false;

  @api selectedRecipients;
  @api selectedItem;

  //To handle invalid email.
  @api isInvalidEmail(){
    this.errorMsg = this.label.InvalidEmailText;
    return this.isError = true;
  }

  connectedCallback() {
    this.init();
  }

  //Defined object and prepopulate values on edit mode.
  init(){
    this.Object  = {"name":"","label":"","variant":"","scope":""};
    this.Object.variant = this.label.ToLabel;
    this.Object.scope = this.label.TabNameandEmail;
    if (!isEmpty(this.selectedItem) && (this.selectedItem.scope == this.label.TabNameandEmail)) {
      this.recipientName = this.selectedItem.label;
      this.recipientEmail = this.selectedItem.name;
      this.isBcc = (this.selectedItem.variant == this.label.BccLabel);
      this.Object = {...this.selectedItem};
      this.dispatchEvent(new CustomEvent('sendinput', {detail: this.selectedItem}));
    }
  }

  //send name,email values to parent component
  handleChange(event){
    if(event.target.name == 'email'){
      this.isError = false;
      this.errorMsg = "";
      this.Object.name = event.target.value;
    } else {
      this.Object.label = event.target.value;
    }
    this.checkDuplicates() ? this.dispatchEvent(new CustomEvent('selection', {})) : this.dispatchEvent(new CustomEvent('sendinput', {detail: this.Object}));
  }

  //handle duplicates for Name and Email section.
  checkDuplicates(){
    for(let getRecipient of this.selectedRecipients) {
      if((getRecipient.name === this.Object.name)){
        if(isEmpty(this.selectedItem)  || (this.Object.name != this.selectedItem.name)){
          this.errorMsg = "Duplicate Row";
          return this.isError = true;
        }
      }
    }
  }

  //Resetting values
  @api saveAndNew(){
    this.selectedItem = null;
    this.init();
    this.template.querySelector('form').reset();
    return;
  }

  //update variant value on change of Bcc checkbox.
  handleBcc(event){
    this.Object.variant = (event.target.checked == true) ? this.label.BccLabel : this.label.ToLabel;;
    this.checkDuplicates() ? this.dispatchEvent(new CustomEvent('selection', {})) : this.dispatchEvent(new CustomEvent('sendinput', {detail: this.Object}));
  }  

}