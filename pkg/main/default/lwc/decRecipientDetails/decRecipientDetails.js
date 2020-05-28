import {api, LightningElement} from 'lwc';
import {Types} from 'c/recipientUtils';

export default class DecRecipientDetails extends LightningElement {

  Types = Types;

  @api
  type;

  @api
  sourceObject;

  @api
  recipient = {};


  get isRecordFieldsLookup() {
    return this.type === this.Types.LookupRecipient.value;
  }

  get isRelatedRecipient() {
    return this.type === this.Types.RelatedRecipient.value;
  }

  get isRoleRecipient() {
    return this.type === this.Types.Role.value;
  }

  get isEntityLookup() {
    return this.type === this.Types.EntityLookup.value;
  }

  get isSigningGroup() {
    return this.type === this.Types.SigningGroup.value;
  }

  get relationship() {
    return this.recipient ? this.recipient.relationship : null;
  }

  set relationship(val) {
    this.recipient.relationship = val;
  }

  updateRecipient(recipient) {
    let evt = new CustomEvent('updaterecipient', {
        detail: recipient
    });
    this.dispatchEvent(evt);
  }

  handleRelationshipUpdate({ detail }) {
    let recipient = this.recipient;
    recipient.relationship = detail;
    this.updateRecipient(recipient);
  }

  updateAction({ detail }) {
    let recipient = this.recipient;
    recipient.type = detail;
    this.updateRecipient(recipient);  
  }

  handleAuthenticationChange() {
      //TODO
  }

  updateNote({ detail }) {
    let recipient = this.recipient;
    recipient.note = detail;
    this.updateRecipient(recipient);        
  }

  handleSourceChange({ detail }) {
    let recipient = this.recipient;
    recipient.source = detail;
    this.updateRecipient(recipient);          
  }
}