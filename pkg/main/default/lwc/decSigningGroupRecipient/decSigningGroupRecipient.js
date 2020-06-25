import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecSigningGroupRecipient extends LightningElement {
  Labels = Labels;

  @api
  signingGroup;

  @api isSending = false;

  handleSelect = ({detail}) => {
    this.dispatchEvent(new CustomEvent(
      'signinggroupchange',
      {
        detail: detail
      }
    ));
  };
}