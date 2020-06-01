import {LightningElement,api} from 'lwc';
import {Labels} from 'c/recipientUtils';

export default class DecRoleRecipient extends LightningElement {
  Labels = Labels;
  @api role = null;
  @api name = null;
  @api email = null;

  roleDetails = null;

  connectedCallback() {
    if (!this.roleDetails) {
      this.roleDetails = {
        role: this.role,
        name: this.name,
        email: this.email
      }
    }
  }

  handleChange = ({ target }) => {
    const paramName = target.name;
    const paramValue = target.value;
    switch(paramName) {
      case 'name':
        this.roleDetails.name = paramValue;
        break;
      case 'email':
        this.roleDetails.email = paramValue;
        break;
      case 'role':
        this.roleDetails.role = paramValue;
        break;
    }

    this.dispatchEvent(new CustomEvent(
      'rolechange',
      {
        detail: this.roleDetails
      }
    ));
  }
}