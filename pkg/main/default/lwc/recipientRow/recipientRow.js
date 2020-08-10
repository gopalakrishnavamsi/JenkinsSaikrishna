import {LightningElement, api} from 'lwc';
import {Labels, Actions, StandardEvents} from 'c/recipientUtils';
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import {genericEvent, isEmpty} from 'c/utils';
import EditLabel from '@salesforce/label/c.Edit';
import DeleteLabel from '@salesforce/label/c.DeleteButtonLabel';
import SelectRecipientLabel from '@salesforce/label/c.SelectRecipient';
import AccessAuthenticationLabel from '@salesforce/label/c.AccessAuthentication';
import PrivateMessageLabel from '@salesforce/label/c.PrivateMessage';
import decTemplate from './decRow.html';
import sendingTemplate from './sendingRow.html';

export default class RecipientRow extends LightningElement {

  @api
  isSending;

  @api
  recipient = {};

  @api
  index = 0;

  @api
  isSigningOrder = false;

  @api
  fromEnvelopeTemplate = false;

  Labels = {
    Edit: EditLabel,
    Delete: DeleteLabel,
    SelectRecipient: SelectRecipientLabel,
    AccessAuthentication: AccessAuthenticationLabel,
    PrivateMessage: PrivateMessageLabel
  };

  context = createMessageContext();

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get isDraggable() {
    return !this.fromEnvelopeTemplate;
  }

  get disableRecipientDelete(){
    return this.recipient && this.recipient.isPlaceHolder;
  }

  get roleName() {
    return this.recipient && !isEmpty(this.recipient.role) && !isEmpty(this.recipient.role.name) ? this.recipient.role.name : null;
  }

  get showPlaceholderEdit() {
    return this.isSending && this.recipient && (isEmpty(this.recipient.name) && isEmpty(this.recipient.email))
  }

  get recipientLabel() {
    if (isEmpty(this.recipient)) return '';
    if (!isEmpty(this.recipient.sourceId)) {
      return this.recipient.name;
    } else if (!isEmpty(this.recipient.relationship)) {
      return this.recipient.relationship.name;
    } else if (!isEmpty(this.recipient.role) && !isEmpty(this.recipient.role.name) && !this.isSending) {
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
      if (this.recipient.relationship.isLookup) return Labels.recipientRecordFieldLabel;
      return Labels.childRelationshipsLabel; 
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

  handleEdit() {
    this.sendRecipientAction(StandardEvents.Edit);
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
    if (isEmpty(event.target.value) || isNaN(event.target.value)) return;
    let payload = {'currentIndex': this.index, 'newRoutingOrder': Number(event.target.value)};
    genericEvent.call(this, 'routingorderupdate', payload, false);
  };

  render() {
    return this.isSending ? sendingTemplate : decTemplate;
  }
}