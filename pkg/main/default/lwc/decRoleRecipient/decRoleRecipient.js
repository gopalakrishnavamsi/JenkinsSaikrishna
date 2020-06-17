import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';

export default class DecRoleRecipient extends LightningElement {
  Labels = Labels;
  @api roleName = null;
  @api name = null;
  @api email = null;

  get hasNameOrEmail() {
    return !isEmpty(this.name) || !isEmpty(this.email);
  }

  handleChange = ({target}) => {
    const paramName = target.name;
    const paramValue = target.value;
    let payLoad = {
      roleName: this.roleName,
      name: this.name,
      email: this.email
    };

    payLoad[paramName] = paramValue;

    this.dispatchEvent(new CustomEvent(
      'rolechange',
      {
        detail: payLoad
      }
    ));
  };
}