import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';
import sendingTemplate from './sendingRoleRecipient.html';
import decTemplate from './decRoleRecipient.html';

export default class DecRoleRecipient extends LightningElement {
  Labels = Labels;
  @api roleName = null;
  @api name = null;
  @api email = null;
  @api isSending = false;
  @api requiresRoleName;
  @api requiresRoleEmail;
  @api isPlaceHolder = false;

  get hasNameOrEmail() {
    return !isEmpty(this.name) || !isEmpty(this.email);
  }

  get disableEditName() {
    return !isEmpty(this.requiresRoleName) && !this.requiresRoleName;
  }

  get disableEditEmail() {
    return !isEmpty(this.requiresRoleEmail) && !this.requiresRoleEmail;
  }

  resetRoleDetails() {
    this.dispatchEvent(new CustomEvent(
      'rolechange',
      {
        detail: { 
          isRoleDetailReset: true
        } 
      }
    ));
  }

  handleChange({target}) {
    const { name = null, value = null} = target;
    this.dispatchEvent(new CustomEvent(
      'rolechange',
      {
        detail: { 
          name, 
          value
        } 
      }
    ));
  }

  render() {
    return this.isSending ? sendingTemplate : decTemplate;
  }
}