import {LightningElement, api} from 'lwc';
import {genericEvent, isEmpty} from 'c/utils';
import {Labels,Actions} from 'c/recipientUtils';

export default class DecRecipient extends LightningElement {

  @api
  recipient = {}

  @api
  index = 0;

  @api
  isSigningOrder = false;

  get recipientLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.relationship)) {
      return this.recipient.relationship.label;
    } else if (!isEmpty(this.recipient.name)) {
      return this.recipient.name;
    } else if (!isEmpty(this.recipient.role)) {
      return this.recipient.role.name;
    } else if (!isEmpty(this.recipient.signingGroup)) {
      return this.recipient.signingGroup.name;
    } else {
      return '';
    }
  }

  get recipientSubLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.relationship)) {
      return Labels.recipientRecordFieldLabel;
    } else if (!isEmpty(this.recipient.email)) {
      return this.recipient.email;
    } else if (!isEmpty(this.recipient.role)) {
      return Labels.recipientRoleLabel;
    } else if (!isEmpty(this.recipient.signingGroup)) {
      return Labels.decSigningGroup;
    } else {
      return '';
    }
  }

  get recipientType() {
    return !isEmpty(this.recipient) && !isEmpty(this.recipient.type) ? Actions[this.recipient.type].label : '';
  }

  get recipientBackgroundColor() {
    if (isEmpty(this.recipient)) return '';
    let colorSequence = this.index > 9 ? this.index % 10 : this.index;
    return 'slds-col ds-recipient-item ds-recipient-color-' + colorSequence;
  }

  handleRoutingOrderChange = (event) =>{
    let payload = {'currentIndex': this.index , 'newRoutingOrder' : event.target.value};
    genericEvent('routingorderupdate', payload, this, false);
  };

}