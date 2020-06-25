import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecipientLookup extends LightningElement {
  Labels = Labels;

  privateSource;

  @api isSending = false;

  @api
  get lookupRecord() {
    return this.privateSource;
  }

  set lookupRecord(val) {
    this.privateSource = val;
  }

  handleRecordSelection({ detail }) {
    let { value, label = Labels.untitledLabel, sublabel = Labels.untitledLabel, objType = null } = detail.record;
    this.dispatchEvent(
      new CustomEvent('recordselection', {
        detail: {
          id: value,
          name: label,
          email: sublabel,
          typeName: objType
        }
      })
    );
  }
}