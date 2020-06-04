import {LightningElement} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRecipientLookup extends LightningElement {
  Labels = Labels;

  handleRecordSelection({ detail }) {
    let { value, label = Labels.untitledLabel,sublabel = Labels.untitledLabel } = detail.record;
    this.dispatchEvent(
      new CustomEvent('recordselection', {
        detail: {
          id: value,
          name: label,
          email: sublabel
        }
      })
    );
  }
}