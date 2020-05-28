import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRelatedRecipient extends LightningElement {
  Labels = Labels;

  @api
  sourceObject = 'Opportunity';

  @api
  relationship;

  get source() {
    return this.sourceObject;
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
}