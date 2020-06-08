import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';
import {Labels} from 'c/recipientUtils';

export default class DecRecipient extends LightningElement {

  privateRecipient;

  @api
  get recipient() {
    return this.privateRecipient;
  }

  set recipient(value) {
    this.privateRecipient = value;
  }

  get recipientLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.relationship)) {
      return this.recipient.relationship.label;
    } else if (!isEmpty(this.recipient.source)) {
      return this.recipient.source.name;
    } else if (!isEmpty(this.recipient.role)) {
      return this.recipient.role.name;
    } else if (!isEmpty(this.recipient.signingGroup)) {
      return this.recipient.signingGroup;
    } else {
      return '';
    }
  }

  get recipientSubLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.relationship)) {
      return Labels.recipientRecordFieldLabel;
    } else if (!isEmpty(this.recipient.source)) {
      return this.recipient.source.email;
    } else if (!isEmpty(this.recipient.role)) {
      return Labels.recipientRoleLabel;
    } else if (!isEmpty(this.recipient.signingGroup)) {
      return Labels.decSigningGroup;
    } else {
      return '';
    }
  }

  get recipientType() {
    return this.recipient.recipientType.label;
  }

  get recipientBackgroundColor() {
    if (isEmpty(this.recipient)) return '';
    let colorSequence = this.recipient.routingOrder > 9 ? this.recipient.routingOrder % 10 : this.recipient.routingOrder;
    return 'slds-col ds-recipient-item ds-recipient-color-' + colorSequence;
  }

}