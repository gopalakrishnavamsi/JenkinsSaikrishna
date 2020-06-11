import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecipientPrivateMessage extends LightningElement {

  Labels = Labels;

  privateNote;

  @api
  get recipientNote() {
    return this.privateNote
  }

  set recipientNote(note = '') {
    this.privateNote = note;
  }

  updateNote = ({target}) => {
    this.dispatchEvent(
      new CustomEvent('notechange', {
        detail: target.value
      })
    )
    this.recipientNote = target.value;

  }

  resetNote = () => {
    this.dispatchEvent(
      new CustomEvent('notechange', {
        detail: null
      })
    )
    this.recipientNote = null;
  }
}