import {LightningElement,api} from 'lwc';
import {Labels, Actions} from 'c/recipientUtils';

export default class DecRecipientAction extends LightningElement {
  Labels = Labels;
  
  Actions = Actions;
  
  @api
  value = 'Signer';

  @api
  readOnly = false;

  @api
  isPlaceHolder = false;

  get options() {
    return this.readOnly && !this.isPlaceHolder ? [this.Actions.CarbonCopy] : Object.values(this.Actions);
  }

  get disableSelect() {
    return this.readOnly  || this.isPlaceHolder;
  }

  handleChange({ detail }) {
    this.dispatchEvent(
      new CustomEvent('actionchange', {
        detail: detail.value
      })
    )
  }
}