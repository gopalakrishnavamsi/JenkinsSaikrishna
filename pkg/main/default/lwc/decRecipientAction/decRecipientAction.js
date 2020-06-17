import {LightningElement,api} from 'lwc';
import {Labels, Actions} from 'c/recipientUtils';

export default class DecRecipientAction extends LightningElement {
  Labels = Labels;
  Actions = Actions;
  @api
  value = 'Signer';

  get options() {
    return Object.values(this.Actions);
  }

  handleChange({ detail }) {
    this.dispatchEvent(
      new CustomEvent('actionchange', {
        detail: detail.value
      })
    )
  }
}