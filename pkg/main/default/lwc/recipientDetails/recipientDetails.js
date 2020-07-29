import {api, LightningElement} from 'lwc';
import {Types, AuthenticationTypes} from 'c/recipientUtils';
import getEntityPhone from '@salesforce/apex/EnvelopeConfigurationController.getEntityPhone';
import {isEmpty} from 'c/utils';

const DEC_DEFAULT_TYPE = Types.LookupRecipient.value;
const SENDING_DEFAULT_TYPE = Types.EntityLookupSending.value;

export default class DecRecipientDetails extends LightningElement {

  @api
  isSending = false;

  Types = Types;

  @api
  type = this.isSending ? SENDING_DEFAULT_TYPE : DEC_DEFAULT_TYPE;

  @api
  sourceObject;

  @api
  recipient = {};

  @api
  readOnly;

  get roleName() {
    return !isEmpty(this.recipient.role) && !isEmpty(this.recipient.role.name) ? this.recipient.role.name : null;
  }

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

  get lookupRecord() {
    return this.recipient ? this.recipient.lookupRecord : null;
  }

  get authentication() {
    return this.recipient ? this.recipient.authentication : null;
  }

  get isValid() {
    return this.isSending ? this.recipient.isSendingReady : this.recipient.isTemplateReady;
  }

  sendValidationEvent(isValid = false) {
    this.dispatchEvent(
      new CustomEvent(
        'validationchange',
        {
          detail: isValid
        }
      )
    );
  }

  handleFilterChange({detail}) {
    this.recipient.filter = detail;
  }

  handleRoleRecipientChange({detail}) {
    const {name = null, value = null, isRoleDetailReset = false} = detail;
    if (isRoleDetailReset) {
      this.recipient.name = null;
      this.recipient.email = null;
    } else {
      if (name === 'roleName')  this.recipient.addRole(value);
      else if (name === 'email' || name === 'name') this.recipient[name] = value;
    }
    this.sendValidationEvent(this.isValid);
  }

  handleRelationshipUpdate = ({detail}) => {
    this.recipient.relationship = detail;
    this.recipient.addRole(detail.name);
    this.sendValidationEvent(this.isValid);
  };

  updateAction = ({detail}) => {
    this.recipient.type = detail;
  };

  handleAuthenticationChange = async ({detail = {}}) => {
    const {type, data = null, isRemove = false} = detail;

    if (isRemove) {
      this.recipient.authentication = null;
      return;
    } else if (type === AuthenticationTypes.AccessCode.value) {
      this.recipient.addAccessCode(data);
      return;
    }

    switch (this.type) {
      case this.Types.EntityLookup.value: {
        const sourceId = this.recipient.sourceId;
        const phone = await getEntityPhone({entityId: sourceId});
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
  };

  updateNote = ({detail}) => {
    this.recipient.note = detail;
  };

  handleSourceChange = ({detail = {}}) => {
    this.recipient.lookupRecord = detail;
    this.sendValidationEvent(this.isValid);
  };

  handleSigningGroupChange = ({detail}) => {
    this.recipient.signingGroup = detail;
    this.sendValidationEvent(this.isValid);
  };
}