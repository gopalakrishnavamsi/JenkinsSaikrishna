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

  get filter() {
    return this.recipient ? this.recipient.filter : null;
  }

  handleFilterChange({ detail }) {
    this.recipient.filter = detail;
  }

  handleRoleRecipientChange({ detail }) {
    const { name = null, email = null, role = null } = detail;
    this.recipient.addRole(role);
    this.recipient.name = name;
    this.recipient.email = email;
  }  

  handleRelationshipUpdate = ({ detail }) => {
    this.recipient.relationship = detail;
  }

  updateAction = ({ detail }) => {
    this.recipient.type = detail;
  }

  handleAuthenticationChange = ({ detail }) => {
    this.recipient.authentication = detail;
  }

  updateNote = ({ detail }) => {
    this.recipient.note = detail;
  }

  handleSourceChange = ({ detail }) => {
    const { name = null, email = null } = detail;
    this.recipient.name = name;
    this.recipient.email = email;
    this.recipient.source = detail;
  }
}