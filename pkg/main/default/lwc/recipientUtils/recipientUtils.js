import {isEmpty} from 'c/utils';
import {Relationship, Filter} from 'c/queryUtils';
//labels
import add from '@salesforce/label/c.Add';
import cancel from '@salesforce/label/c.Cancel';
import addRecipient from '@salesforce/label/c.AddRecipient';
import decFromSalesforce from '@salesforce/label/c.DecFromSalesforce';
import otherSourcesText from '@salesforce/label/c.OtherSourcesText';
import addRecipientsEmptyImage from '@salesforce/resourceUrl/DecAddRecipientsEmpty';
import helpVideoText from '@salesforce/label/c.DecRecipientsVideoText';
import helpVideoLength from '@salesforce/label/c.DecRecipientsVideoLength';
import helpVideoLink from '@salesforce/label/c.DecRecipientsVideoLink';
import decAddRecipients from '@salesforce/label/c.DecAddRecipients';
import decAddRecipientsDescription from '@salesforce/label/c.DecAddRecipientsDescription';
import decAddRecipientsDescription2 from '@salesforce/label/c.DecAddRecipientsDescription2';
import recipients from '@salesforce/label/c.Recipients';
import decRecordFields from '@salesforce/label/c.DecRecordFields';
import childRelationships from '@salesforce/label/c.ChildRelationships';
import decUsersOrContacts from '@salesforce/label/c.DecUsersOrContacts';
import decByRole from '@salesforce/label/c.DecByRole';
import decSigningGroup from '@salesforce/label/c.DecSigningGroup';
import decRecordFieldsTitle1 from '@salesforce/label/c.DecRecordFieldsTitle1';
import decRecordFieldsTitle2 from '@salesforce/label/c.DecRecordFieldsTitle2';
import accessCodeLabel from '@salesforce/label/c.AccessCode';
import decSMSorPhone from '@salesforce/label/c.DecSMSorPhone';
import decRoleRecipientTitle from '@salesforce/label/c.DecRoleRecipientTitle';
import decSigningGroupRecipientTitle from '@salesforce/label/c.DecSigningGroupRecipientTitle';
import decSigningGroupLearnMoreLink from '@salesforce/label/c.DecSigningGroupLearnMoreLink';
import decSearchByGroupNamePlaceHolder from '@salesforce/label/c.DecSearchByGroupNamePlaceHolder';
import learnMore from '@salesforce/label/c.LearnMore';
import decSelectGroup from '@salesforce/label/c.DecSelectGroup';
import decEntityLookupRecipientTitle from '@salesforce/label/c.DecEntityLookupRecipientTitle';
import decSelectUserOrContact from '@salesforce/label/c.DecSelectUserOrContact';
import decAddPrivateMessage from '@salesforce/label/c.DecAddPrivateMessage';
import privateMessage from '@salesforce/label/c.PrivateMessage';
import accessAuthentication from '@salesforce/label/c.AccessAuthentication';
import decAddAccessAuthentication from '@salesforce/label/c.DecAddAccessAuthentication';
import decRecipientAction from '@salesforce/label/c.DecRecipientAction';
import signerLabel from '@salesforce/label/c.Signer';
import carbonCopyLabel from '@salesforce/label/c.CarbonCopy';
import certifiedDeliveryLabel from '@salesforce/label/c.CertifiedDelivery';
import agentLabel from '@salesforce/label/c.Agent';
import editorLabel from '@salesforce/label/c.Editor';
import inPersonSignerLabel from '@salesforce/label/c.InPersonSignerLabel';
import embeddedSignerLabel from '@salesforce/label/c.EmbeddedSigner';
import decRecordsFieldsLookupLabel from '@salesforce/label/c.DecRecordsFieldsLookupLabel';
import decRelatedListLabel from '@salesforce/label/c.DecRelatedListLabel';
import untitledLabel from '@salesforce/label/c.Untitled';
import signingOrderLabel from '@salesforce/label/c.SigningOrder';
import searchPlaceHolder from '@salesforce/label/c.SearchPlaceHolder';
import addFilterLabel from '@salesforce/label/c.AddFilterLabel';
import emailAddressLabel from '@salesforce/label/c.EmailAddress';
import nameLabel from '@salesforce/label/c.NameLabel';
import recipientRoleLabel from '@salesforce/label/c.RecipientRoleLabel';
import recipientRecordFieldLabel from '@salesforce/label/c.RecipientRecordFieldLabel';
import view from '@salesforce/label/c.View';
import addAndNew from '@salesforce/label/c.AddAndNew';
import DEC_DELETE_RECIPIENT from '@salesforce/messageChannel/DecDeleteRecipient__c';
import DEC_EDIT_RECIPIENT from '@salesforce/messageChannel/DecEditRecipient__c';

//eslint-disable-next-line
const emailRegEx = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;

export class Recipient {
  constructor({id = null, name = null, email = null, sequence = null, phone = null, authentication = null, emailSettings = null, note = null, readOnly = false, required = false, source = null, type = 'Signer', signingGroup = null}, role, routingOrder = 1) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.sequence = sequence;
    this.authentication = authentication;
    this.emailSettings = emailSettings;
    this.note = note;
    this.readOnly = readOnly;
    this.required = required;
    this.signingGroup = signingGroup;
    this.source = source;
    this.routingOrder = routingOrder;
    this.type = type;
    this.role = role;
  }

  static fromObject(recipientDetails = {}) {
    if (isEmpty(recipientDetails)) return null;

    if (recipientDetails.relationship) {
      if (recipientDetails.relationship.isLookup) {
        return new LookupRecipient(
          Relationship.fromObject(recipientDetails.relationship),
          recipientDetails.role,
          recipientDetails.routingOrder,
          {
            ...recipientDetails,
            authentication: new Authentication(recipientDetails.authentication ? recipientDetails.authentication : {})
          }
        );
      } else {
        return new RelatedRecipient(
          Relationship.fromObject(recipientDetails.relationship),
          recipientDetails.roles,
          recipientDetails.incrementRoutingOrder,
          recipientDetails.routingOrder,
          Filter.fromObject(recipientDetails.filter || {}),
          {
            ...recipientDetails,
            authentication: new Authentication(recipientDetails.authentication ? recipientDetails.authentication : {})
          }
        );
      }
    }

    return new Recipient(
      {
        ...recipientDetails,
        authentication: new Authentication(recipientDetails.authentication ? recipientDetails.authentication : {})
      },
      recipientDetails.role,
      recipientDetails.routingOrder
    );
  }

  get isPlaceHolder() {
    return this.constructor === Recipient && !isEmpty(this.role) && isEmpty(this.signingGroup) && isEmpty(this.name) && isEmpty(this.email);
  }

  get sourceId() {
    return this.source && this.source.id ? this.source.id : null;
  }

  get hasAuthentication() {
    return !isEmpty(this.authentication) && !isEmpty(this.authentication.type);
  }

  get hasNote() {
    return !isEmpty(this.note);
  }

  get recipientType() {
    switch (this.constructor) {
      case LookupRecipient:
        return Types.LookupRecipient.value;
      case RelatedRecipient:
        return Types.RelatedRecipient.value;
      default:
        if (this.signingGroup) return Types.SigningGroup.value;
        else if (!isEmpty(this.source)) return Types.EntityLookup.value;
        return Types.Role.value;
    }
  }

  get hasRelationship() {
    return !isEmpty(this.relationship);
  }

  get hasFilter() {
    return !isEmpty(this.filter);
  }

  get isValidEmail() {
    if (isEmpty(this.email)) return false;
    return emailRegEx.test(this.email);
  }

  get isValid() {
    if (!isEmpty(this.signingGroup)) return true;
    if (!isEmpty(this.sourceId)) return true;
    if (this.relationship) return !this.relationship.isEmpty;

    return (!isEmpty(this.role) && !this.role.isEmpty) || (!isEmpty(this.name) && this.isValidEmail);
  }

  get lookupRecord() {
    if (isEmpty(this.source)) return null;
    const {id = null, typeName = ''} = this.source;
    return !isEmpty(id) ? {
      label: this.name,
      value: id,
      sublabel: this.email,
      objType: typeName
    } : null;
  }

  set lookupRecord({name = null, email = null, id = null, typeName = null}) {
    if (isEmpty(id)) return;
    this.name = name;
    this.email = email;
    this.source = {
      name,
      id,
      typeName
    };
  }

  addRole(name) {
    this.role = new Role(name, this.routingOrder);
  }

  addSMSAuthentication(phone = null) {
    if (isEmpty(phone)) return;
    this.authentication = new Authentication({phone});
  }

  addAccessCode(accessCode = null) {
    if (isEmpty(accessCode)) return;
    this.authentication = new Authentication({accessCode});
  }
}

export class LookupRecipient extends Recipient {
  constructor(relationship, role, routingOrder, props = {}) {
    super(props, role, routingOrder);
    this.relationship = isEmpty(relationship) ? new Relationship() : relationship;
  }

  addSMSAuthentication() {
    this.authentication = new Authentication({idCheckRequired: true});
  }
}

export class RelatedRecipient extends Recipient {
  constructor(relationship, roles = [], incrementRoutingOrder, routingOrder, filter, props = {}) {
    super(props, null, routingOrder);
    this.relationship = isEmpty(relationship) ? new Relationship(false) : relationship;
    this.roles = roles;
    this.incrementRoutingOrder = incrementRoutingOrder;
    this.filter = filter;
  }

  addSMSAuthentication() {
    this.authentication = new Authentication({idCheckRequired: true});
  }

  addFilter(filterBy) {
    this.filter = new Filter(filterBy);
  }
}


class Role {
  constructor(name, value = 1) {
    this.name = name;
    this.value = value;
  }

  get isEmpty() {
    return isEmpty(this.name);
  }
}

export class Authentication {
  constructor({phone = null, accessCode = null, idCheckRequired = false}) {
    this.smsPhoneNumbers = !isEmpty(phone) ? [phone] : null;
    this.accessCode = !isEmpty(accessCode) && !isNaN(accessCode) ? parseInt(accessCode) : null;
    this.idCheckRequired = idCheckRequired;
  }

  get phoneValue() {
    return !isEmpty(this.smsPhoneNumbers) && !isEmpty(this.smsPhoneNumbers[0]) ? this.smsPhoneNumbers[0] : null;
  }

  set phoneValue(phone) {
    this.smsPhoneNumbers = !isEmpty(phone) ? [phone] : null;
  }

  get type() {
    return !isEmpty(this.accessCode) ? AuthenticationTypes.AccessCode.value : !isEmpty(this.phoneValue) || this.idCheckRequired === true ? AuthenticationTypes.SMSOrPhone.value : null;
  }
}

export const Labels = {
  add: add,
  cancel: cancel,
  addRecipient: addRecipient,
  decFromSalesforce: decFromSalesforce,
  otherSourcesText: otherSourcesText,
  addRecipientsEmptyImage: addRecipientsEmptyImage,
  helpVideoText: helpVideoText,
  helpVideoLength: helpVideoLength,
  helpVideoLink: helpVideoLink,
  decAddRecipients: decAddRecipients,
  decAddRecipientsDescription: decAddRecipientsDescription,
  decAddRecipientsDescription2: decAddRecipientsDescription2,
  recipients: recipients,
  decRecordFieldsTitle1: decRecordFieldsTitle1,
  decRecordFieldsTitle2: decRecordFieldsTitle2,
  decRoleRecipientTitle: decRoleRecipientTitle,
  decSigningGroupRecipientTitle: decSigningGroupRecipientTitle,
  decSigningGroupLearnMoreLink: decSigningGroupLearnMoreLink,
  decSearchByGroupNamePlaceHolder: decSearchByGroupNamePlaceHolder,
  learnMore: learnMore,
  decSelectGroup: decSelectGroup,
  decEntityLookupRecipientTitle: decEntityLookupRecipientTitle,
  decSelectUserOrContact: decSelectUserOrContact,
  decAddPrivateMessage: decAddPrivateMessage,
  privateMessage: privateMessage,
  accessAuthentication: accessAuthentication,
  decAddAccessAuthentication: decAddAccessAuthentication,
  decRecipientAction: decRecipientAction,
  decRecordsFieldsLookupLabel: decRecordsFieldsLookupLabel,
  decRelatedListLabel: decRelatedListLabel,
  untitledLabel: untitledLabel,
  addFilterLabel: addFilterLabel,
  signingOrderLabel: signingOrderLabel,
  searchPlaceHolder: searchPlaceHolder,
  emailAddressLabel: emailAddressLabel,
  nameLabel: nameLabel,
  recipientRoleLabel: recipientRoleLabel,
  recipientRecordFieldLabel: recipientRecordFieldLabel,
  view: view,
  addAndNew: addAndNew,
  accessCodeLabel: accessCodeLabel,
  decSMSorPhone: decSMSorPhone,
  decSigningGroup: decSigningGroup
};

export const Actions = {
  Signer: {
    value: 'Signer',
    label: signerLabel
  },
  InPersonSigner: {
    value: 'InPersonSigner',
    label: inPersonSignerLabel
  },
  EmbeddedSigner: {
    value: 'EmbeddedSigner',
    label: embeddedSignerLabel
  },
  CarbonCopy: {
    value: 'CarbonCopy',
    label: carbonCopyLabel
  },
  CertifiedDelivery: {
    value: 'CertifiedDelivery',
    label: certifiedDeliveryLabel
  },
  Agent: {
    value: 'Agent',
    label: agentLabel
  },
  Editor: {
    value: 'Editor',
    label: editorLabel
  }
};

export const Types = {
  LookupRecipient: {
    value: 'LookupRecipient',
    label: decRecordFields
  },
  RelatedRecipient: {
    value: 'RelatedRecipient',
    label: childRelationships
  },
  EntityLookup: {
    value: 'Entity',
    label: decUsersOrContacts
  },
  Role: {
    value: 'Role',
    label: decByRole
  },
  SigningGroup: {
    value: 'SigningGroup',
    label: decSigningGroup
  }
};

export const AuthenticationTypes = {
  SMSOrPhone: {
    value: 'SMS/Phone',
    label: decSMSorPhone
  },
  AccessCode: {
    value: 'AccessCode',
    label: accessCodeLabel
  }
};

export const StandardEvents = {
  Delete: DEC_DELETE_RECIPIENT,
  Edit: DEC_EDIT_RECIPIENT
};

export class RecipientGroupedByRoutingOrder {
  constructor(routingOrder, groupedRecipients) {
    this.routingOrder = routingOrder;
    this.hasAdditionalRecipients = groupedRecipients.length > 2;
    let recipientGroupedBySigningOrder =
      groupedRecipients.map((obj, index) => ({
        ...obj,
        initials: obj.name ? this.parseInitial(obj.name) : '',
        customId: obj.name && index < 2 ? this.parseInitial(obj.name) + (index + 1) : '',
        index: index + 1
      }));
    this.additionalRecipients = this.hasAdditionalRecipients ? recipientGroupedBySigningOrder.slice(2, recipientGroupedBySigningOrder.length) : [];
    this.numberOfAdditionalRecipients = this.hasAdditionalRecipients ? this.additionalRecipients.length : 0;
    this.recipients = recipientGroupedBySigningOrder.slice(0, 2);
    this.routingOrderString = `r${this.routingOrder}`;
  }

  parseInitial = (name) => {
    let initials = name.match(/\b\w/g) || [];
    return ((initials.shift() || '') + (initials.pop() || '')).toUpperCase();
  };
}