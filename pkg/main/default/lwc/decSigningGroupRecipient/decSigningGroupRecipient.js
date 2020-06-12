import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecSigningGroupRecipient extends LightningElement {
  Labels = Labels;

  @api
  signingGroup;

  handleSelect = ({detail}) => {
    this.signingGroup = detail;
    this.dispatchEvent(new CustomEvent(
      'signinggroupchange',
      {
        detail: this.signingGroup
      }
    ));
  };
}