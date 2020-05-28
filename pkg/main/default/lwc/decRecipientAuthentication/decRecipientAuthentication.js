import {LightningElement} from 'lwc';
import {AuthenticationTypes, Labels} from 'c/recipientUtils';

export default class DecRecipientAuthentication extends LightningElement {
  AuthenticationTypes = AuthenticationTypes;
  Labels = Labels;
  value = '';

  get options() {
    return Object.values(this.AuthenticationTypes);
  }

  handleChange({ detail }) {
    this.dispatchEvent(
      new CustomEvent('authenticationchange', {
        detail: detail.value
      })
    )
  }
}
