import {api, LightningElement} from 'lwc';
import {Types, AuthenticationTypes} from 'c/recipientUtils';
import getEntityPhone from '@salesforce/apex/EnvelopeConfigurationController.getEntityPhone';
const DEFAULT_TYPE = Types.LookupRecipient.value;

export default class DecRecipientDetails extends LightningElement {

  Types = Types;

  @api
  type = DEFAULT_TYPE;

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

  sendValidationEvent(isValid = false) {
    this.dispatchEvent(
      new CustomEvent(
        'validationchange',
        {
          detail: isValid
        }
      )
    )
  }

  handleFilterChange({ detail }) {
    this.recipient.filter = detail;
  }

  handleRoleRecipientChange({ detail }) {
    const { name = null, email = null, role = null } = detail;
    this.recipient.addRole(role);
    this.recipient.name = name;
    this.recipient.email = email;
    this.sendValidationEvent(this.recipient.isValid);
  }  

  handleRelationshipUpdate = ({ detail }) => {
    this.recipient.relationship = detail;
    this.sendValidationEvent(this.recipient.isValid);
  }

  updateAction = ({ detail }) => {
    this.recipient.type = detail;
  }

  handleAuthenticationChange = async ({ detail = {} }) => {
    const { type, data = null, isRemove = false } = detail;

    if (isRemove) {
      this.recipient.authentication = null;
      return;
    } else if (type === AuthenticationTypes.AccessCode.value) {
      this.recipient.addAccessCode(data);
      return;
    } 

    switch(this.type) {
      case this.Types.EntityLookup.value: {
        const sourceId = this.recipient.sourceId;
        const phone = await getEntityPhone({ entityId: sourceId});
        this.recipient.addSMSAuthentication(phone);
        break;
      }
      case this.Types.LookupRecipient.value:
      case this.Types.RelatedRecipient.value:
        this.recipient.addSMSAuthentication();
        break;
      default:
        this.recipient.addSMSAuthentication(data);
        break;
    }
  }

  updateNote = ({ detail }) => {
    this.recipient.note = detail;
  }

  handleSourceChange = ({ detail }) => {
    const { name = null, email = null } = detail;
    this.recipient.name = name;
    this.recipient.email = email;
    this.recipient.source = detail;
    this.sendValidationEvent(this.recipient.isValid);
  }

  handleSigningGroupChange = ({ detail }) => {
    this.recipient.signingGroup = detail;
    this.sendValidationEvent(this.recipient.isValid);
  }
}