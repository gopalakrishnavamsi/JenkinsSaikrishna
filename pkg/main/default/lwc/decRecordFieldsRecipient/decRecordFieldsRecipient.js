import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecordFieldsRecipient extends LightningElement {
  Labels = Labels;

  @api
  sourceObject = 'Opportunity';    

  @api
  relationship;

  get isLookup() {
      return true;
  }

  handleSelect({ detail }) {
    this.relationship = detail;
    this.dispatchEvent(
      new CustomEvent(
        'relationshipupdate',
        {
            detail 
        }
      )
    );
  }

  get source() {
    return this.sourceObject;
  }
}