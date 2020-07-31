import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import { isEmpty } from 'c/utils';

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

  get hasNote() {
    return !isEmpty(this.recipientNote);
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
        detail: ''
      })
    )
    this.recipientNote = '';
  }
}