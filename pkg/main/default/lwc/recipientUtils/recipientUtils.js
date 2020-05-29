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

export class Recipient {
  constructor({id = null, name = null, email = null, sequence = null, phone = null, authentication = null, emailSettings = null, note = null, readOnly = false, required = false, source = null, type = null, signingGroup = null}, role, routingOrder = 1) {
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

  get isPlaceHolder() {
    return this.constructor === Recipient && !isEmpty(this.role) && isEmpty(this.signingGroup) && isEmpty(this.name) && isEmpty(this.email);
  }

  get hasAuthentication() {
    return !isEmpty(this.authentication);
  }

  get hasNote() {
    return !isEmpty(this.note);
  }

  get recipientType() {
    switch(this.constructor) {
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

  addSMSAuthentication(phoneNumber = null) {
    if (isEmpty(phoneNumber)) return;
    this.authentication = {
      smsPhoneNumbers: [phoneNumber]
    };
  }

  addAccessCode(accessCode = null) {
    if (isEmpty(accessCode)) return;
    this.authentication = {
      accessCode: parseInt(accessCode)
    };
  }
}

export class LookupRecipient extends Recipient {
  constructor(relationship, role, routingOrder, props = {}) {
    super(props, role, routingOrder);
    this.relationship = isEmpty(relationship) ? new Relationship() : relationship;
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

  addFilter(filterBy) {
    this.filter = new Filter(filterBy);
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
  untitledLabel: untitledLabel
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
    value: 'Access Code',
    label: accessCodeLabel
  }
};