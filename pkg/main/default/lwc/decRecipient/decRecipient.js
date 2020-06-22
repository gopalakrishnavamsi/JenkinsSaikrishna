import {LightningElement, api} from 'lwc';
import {Labels, Actions, StandardEvents} from 'c/recipientUtils';
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import {genericEvent, isEmpty} from 'c/utils';
import EditLabel from '@salesforce/label/c.Edit';
import DeleteLabel from '@salesforce/label/c.DeleteButtonLabel';

export default class DecRecipient extends LightningElement {

  @api
  recipient = {};

  @api
  index = 0;

  @api
  isSigningOrder = false;

  Labels = {
    Edit: EditLabel,
    Delete: DeleteLabel
  };

  context = createMessageContext();

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get recipientLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.relationship)) {
      return this.recipient.relationship.label;
    } else if (!isEmpty(this.recipient.role)) {
      return this.recipient.role.name;
    } else if (!isEmpty(this.recipient.name)) {
      return this.recipient.name;
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

  handleRecipientAction = ({target}) => {
    const action = target.value;
    switch (action) {
      case 'edit':
        this.sendRecipientAction(StandardEvents.Edit);
        break;
      case 'delete':
        this.sendRecipientAction(StandardEvents.Delete);
        break;
    }
  };

  sendRecipientAction(event) {
    if (!event) return;
    publish(
      this.context,
      event,
      {
        index: this.index
      }
    );
  }

  handleRoutingOrderChange = (event) => {
    if (isEmpty(event.target.value)) return;
    let payload = {'currentIndex': this.index, 'newRoutingOrder': event.target.value};
    genericEvent.call(this, 'routingorderupdate', payload, false);
  };
}