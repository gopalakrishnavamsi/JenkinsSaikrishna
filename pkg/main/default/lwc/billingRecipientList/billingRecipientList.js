import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';
import Edit from '@salesforce/label/c.Edit';
import Delete from '@salesforce/label/c.DeleteButtonLabel';
import TabNameandEmail from '@salesforce/label/c.TabNameandEmail';
import RecipientRecordFieldLabel from '@salesforce/label/c.RecipientRecordFieldLabel';

export default class BillingRecipientList extends LightningElement {

  label = {
    Edit,
    Delete,
    TabNameandEmail,
    RecipientRecordFieldLabel
  };

  @api selectedRowItem;
  @api index;

  get recipientLabel() {
    return !isEmpty(this.selectedRowItem.label) ? this.selectedRowItem.label: 'NA' ;
  }

  get scope() {
    return (this.selectedRowItem.scope == this.label.TabNameandEmail) ? this.selectedRowItem.name : this.label.RecipientRecordFieldLabel;
  }

  //dispatches a custom event after clicking edit button.
  handleEdit() {
    this.dispatchEvent(new CustomEvent('edititem', {detail: this.index}));
  }

  //dispatches a custom event after clicking delete button.
  handleDelete() {
  this.dispatchEvent(new CustomEvent('deleteitem', {detail: this.index}));
  }
  
}