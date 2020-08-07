import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import { isEmpty } from 'c/utils';

export default class DecRecipientPrivateMessage extends LightningElement {

  Labels = Labels;

  privateNote;

  @api
  forbidChanges = false;

  hasNote;

  @api
  get recipientNote() {
    return this.privateNote
  }

  set recipientNote(note = '') {
    this.privateNote = note;

    if (isEmpty(this.hasNote)) {
      this.hasNote = !isEmpty(note);
    }
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
    this.hasNote = false;
    this.recipientNote = '';
  }
}