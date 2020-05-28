import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecipientPrivateMessage extends LightningElement {

  Labels = Labels;

  @api
  recipientNote = {};

  updateNote({target}) {
    this.dispatchEvent(
      new CustomEvent('notechange', {
        detail: target.value
      })
    )
    this.recipientNote = target.value;

  }
}