import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';
import DynamicRecipientHelpText from '@salesforce/label/c.DynamicRecipientHelpText';
import DynamicRecipientLabel from '@salesforce/label/c.DynamicRecipientLabel';
import DecRecordFields from '@salesforce/label/c.DecRecordFields';
import SearchPlaceHolder from '@salesforce/label/c.SearchPlaceHolder';

export default class BillingRecordField extends LightningElement {

  label = {
    DynamicRecipientHelpText,
    DynamicRecipientLabel,
    DecRecordFields,
    SearchPlaceHolder
  };

  selectedValue;
  recipients = [];
  getRecipientResult = null;
  showListPanel;

  @api getRecipientItem;
  @api selectedRecipients;
  @api sourceRecipientData;

  get resultClass() {
    return this.showListPanel ?
      'slds-form-element slds-lookup slds-is-open' :
      'slds-form-element slds-lookup slds-is-close';
  }

  get showResultPanel() {
    return !isEmpty(this.getRecipientResult);
  }

  //refine the recipient dropdown list based on search key
  handleChange(event) {
    if (!isEmpty(event.target.value)) {      
      this.getRecipientResult = this.recipients.filter(r => r.label.toLowerCase().indexOf(event.target.value.toLowerCase()) > -1);
      this.showListPanel = (this.getRecipientResult.length > 0) ? true : false;
    } else {
        this.selectedValue = null;
        this.showListPanel = false;
        this.dispatchEvent(new CustomEvent('selection', {}));
      }
  }

  //Get apex result from parent and prepopulate values on edit mode
  initRecipients = () => {
    this.recipients = [...this.sourceRecipientData];
    if (this.selectedRecipients.length > 0) {
      this.removeDuplicates();
    }
    if (!isEmpty(this.getRecipientItem) && (this.getRecipientItem.scope == this.label.DecRecordFields)) {
      this.selectedValue = this.getRecipientItem.label;
      this.dispatchEvent(new CustomEvent('recipientupdate', {detail: this.getRecipientItem}));
    }
  };

  //remove value after selection of recipient drop-down
  removeDuplicates() {
    for(let i=0;i<this.selectedRecipients.length;i++){
      for(let j=0;j<this.recipients.length;j++){
        if( this.selectedRecipients[i].name === this.recipients[j].name )
          this.recipients.splice(j , 1);
      }
      }
  }

  connectedCallback() {
   this.initRecipients();
  }
  
  //send selected index to parent component.
  handleSelect = ({detail}) => {
    this.selectedValue=this.getRecipientResult[detail].label;
    this.dispatchEvent(new CustomEvent('recipientupdate', {detail: this.getRecipientResult[detail]}));
    this.getRecipientResult = null;
  };

  //on hitting, Add & New button resetting values
  @api saveAndNew(){    
    this.initRecipients();
    this.selectedValue = null;
    return ;
  }
  
}