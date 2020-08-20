import {LightningElement, api} from 'lwc';
import {Labels, Recipient, StandardEvents, RoleQueue, Types} from 'c/recipientUtils';
import {
  isEmpty,
  proxify,
  removeArrayElement,
  subscribeToMessageChannel,
  editArrayElement,
  groupBy,
  genericEvent
} from 'c/utils';
import {createMessageContext, releaseMessageContext} from 'lightning/messageService';
import decTemplate from './decRecipients.html';
import sendingTemplate from './sendingRecipients.html';


const DEFAULT_ROUTING_ORDER = 1;

export default class Recipients extends LightningElement {

  @api isSending;

  @api readOnly;

  @api fromEnvelopeTemplate = false;

  Labels = Labels;

  showAddRecipientsModal = false;

  privateRecipients = proxify([]);

  privateDefaultRoles = null;

  editRecipientIndex = null;

  isSigningOrder = false;

  isDirtyRecipients = false;

  isEmptyRecipients = false;

  originalEditRecipient = null;

  @api
  sourceObject;

  context = createMessageContext();

  @api
  get recipients() {
    return this.privateRecipients;
  }

  set recipients(val) {
    this.privateRecipients = proxify(!isEmpty(val) ? val.map(r => Recipient.fromObject({
      ...r
    })) : []);
    this.isEmptyRecipients = isEmpty(this.privateRecipients) || (!isEmpty(this.privateRecipients) && this.privateRecipients.length === 0);
    genericEvent.call(this, 'emptyrecipients', this.isEmptyRecipients, false);
  }

  @api
  get defaultRoles() {
    return this.privateDefaultRoles;
  }

  set defaultRoles(val = []) {
    this.privateDefaultRoles = new RoleQueue(
      val, 
      () => {
        let roles = [];
        this.recipients.forEach((r) => {
          if (r.recipientType === Types.RelatedRecipient.value && !isEmpty(r.roles) && r.roles.length > 0) roles.push(...r.roles.map(rr => rr.toUpperCase()));
          else if (!isEmpty(r.role) && !isEmpty(r.role.name)) roles.push(r.role.name.toUpperCase())
        })
        return roles;
      }
    )
  }

  connectedCallback() {
    this.deleteChannelEvent = subscribeToMessageChannel(
      this.context,
      this.deleteChannelEvent,
      StandardEvents.Delete,
      this.handleDeleteRecipient
    );

    this.editChannelEvent = subscribeToMessageChannel(
      this.context,
      this.editChannelEvent,
      StandardEvents.Edit,
      this.handleEditRecipient
    );

    if (!isEmpty(this.recipients)) {
      //Apply Default Roles
      if (this.defaultRoles && this.isSending) {
        for(let recipient of this.recipients) {
          if (isEmpty(recipient.role) || recipient.role.isEmpty) recipient.role = this.defaultRoles.getNextRole();
        }
      }
      let recipientsGroup = groupBy(this.recipients, 'routingOrder');
      Object.keys(recipientsGroup).forEach(function (key) {
        if (parseInt(key) > DEFAULT_ROUTING_ORDER) {
          this.isSigningOrder = true;
        }
      }, this);
    }
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @api
  fetchRecipients() {
    return {'data': this.privateRecipients, 'isDirtyRecipients': this.isDirtyRecipients};
  }

  get signingOrderButtonIcon() {
    return this.isSigningOrder ? 'utility:check' : 'utility:add';
  }

  get hasRecipients() {
    return !isEmpty(this.privateRecipients) && this.privateRecipients.length > 0;
  }

  get editRecipient() {
    return isEmpty(this.editRecipientIndex) ? null : this.recipients[this.editRecipientIndex];
  }

  set editRecipient(val) {
    this.recipients = editArrayElement(this.recipients, this.editRecipientIndex, val);
  }

  closeRecipientsModal = () => {
    this.showAddRecipientsModal = false;
    if (!isEmpty(this.editRecipientIndex)) this.editRecipientIndex = null;
  };

  cancelSave = () => {
    if (!isEmpty(this.editRecipientIndex) && !isEmpty(this.originalEditRecipient)) {
      this.editRecipient = this.originalEditRecipient;
      this.editRecipientIndex = null;
      this.originalEditRecipient = null;
    }
    this.closeRecipientsModal();
  };  

  handleRecipientsModalOpen = () => {
    this.showAddRecipientsModal = true;
  };

  removeRecipient = (index) => {
    this.isDirtyRecipients = true;
    this.recipients = removeArrayElement(this.recipients, index);
  };

  addRecipient = (recipient, isAddNew = false) => {
    this.isDirtyRecipients = true;
    const isEdit = !isEmpty(this.editRecipientIndex);

    if (this.isSigningOrder && !isEdit) {
      const maxRoutingOrder = Math.max(...this.recipients.map(r => r.routingOrder), 0);
      recipient.routingOrder = maxRoutingOrder + 1;
    } else if (!isEdit) recipient.routingOrder = DEFAULT_ROUTING_ORDER;
  
    if (this.isSending && !isEmpty(this.defaultRoles) && (isEmpty(recipient.role) || recipient.role.isEmpty)) {
      recipient.role = this.defaultRoles.getNextRole();
    }

    if (isEdit) {
      this.editRecipient = recipient;
      this.editRecipientIndex = null;
    } else this.recipients = [...this.recipients, recipient];

    this.closeRecipientsModal();
    if (isAddNew) this.handleRecipientsModalOpen();
  };

  handleDeleteRecipient = ({index}) => {
    this.isDirtyRecipients = true;
    if (isEmpty(index) || isEmpty(this.recipients) || isEmpty(this.recipients[index])) return;
    this.recipients = removeArrayElement(this.recipients, index);
  };

  handleEditRecipient = ({index}) => {
    this.editRecipientIndex = index;
    //Save original state of recipient if edit flow is cancelled.
    this.originalEditRecipient = this.editRecipient.clone();
    this.showAddRecipientsModal = true;
  };

  handleSigningOrderModalOpen = () => {
    const signingOrderDiagramComponent = this.template.querySelector('c-signing-order');
    signingOrderDiagramComponent.handleShow();
  };

  isDuplicate = (recipient) => {
    return this.recipients.some((r, index) => {
      if (this.editRecipientIndex === index) return false;
      return r.equals(recipient)
    });
  }

  handleRecipientSigningOrder = () => {
    this.isDirtyRecipients = true;
    this.isSigningOrder = !this.isSigningOrder;
    this.recipients = this.recipients.map((r, index) => ({
      ...r,
      routingOrder: this.isSigningOrder ? index + 1 : DEFAULT_ROUTING_ORDER
    }));
  };

  handleRecipientsUpdate = (event) => {
    this.isDirtyRecipients = true;
    if (event.detail.data) {
      this.recipients = event.detail.data.sort(function (x, y) {
        return x.routingOrder - y.routingOrder;
      });
    }
  };

  handleDragRecipientsUpdate = (event) => {
    this.isDirtyRecipients = true;
    if (event.detail.data) {
      this.recipients = event.detail.data;
    }
  };

  render() {
    return this.isSending ? sendingTemplate : decTemplate;
  }
}