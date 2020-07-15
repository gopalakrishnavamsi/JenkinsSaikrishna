import docuSign from '@salesforce/label/c.DocuSign';
import sendWithDocuSign from '@salesforce/label/c.SendWithDocuSign';
import cancel from '@salesforce/label/c.Cancel';
import exit from '@salesforce/label/c.Exit';
import back from '@salesforce/label/c.Back';
import next from '@salesforce/label/c.Next';
import send from '@salesforce/label/c.Send';
import exitSendForSignature from '@salesforce/label/c.ExitSendForSignature';
import progressLostOnExit from '@salesforce/label/c.ProgressLostOnExit';
import atLeastOneDocumentIsRequired from '@salesforce/label/c.AtLeastOneDocumentIsRequired';
import documents from '@salesforce/label/c.Documents';
import recipients from '@salesforce/label/c.Recipients';
import prepareAndSend from '@salesforce/label/c.PrepareAndSend';
import defaultEmailSubject from '@salesforce/label/c.DefaultEmailSubject';
import defaultEmailMessage from '@salesforce/label/c.DefaultEmailMessage';
import {isEmpty} from 'c/utils';

const LABEL = {
  docuSign,
  sendWithDocuSign,
  cancel,
  exit,
  back,
  next,
  send,
  exitSendForSignature,
  progressLostOnExit,
  atLeastOneDocumentIsRequired,
  documents,
  recipients,
  prepareAndSend,
  defaultEmailSubject,
  defaultEmailMessage
};

const PROGRESS_STEP = {
  DOCUMENTS: '1',
  RECIPIENTS: '2',
  PREPARE_AND_SEND: '3'
};

const OPERATION = {
  BACK: 'back',
  NEXT: 'next'
};

const MIN_STEP = PROGRESS_STEP.DOCUMENTS;
const MAX_STEP = PROGRESS_STEP.PREPARE_AND_SEND;

const STEPS = [
  {'label': LABEL.documents, 'value': PROGRESS_STEP.DOCUMENTS},
  {'label': LABEL.recipients, 'value': PROGRESS_STEP.RECIPIENTS},
  {'label': LABEL.prepareAndSend, 'value': PROGRESS_STEP.PREPARE_AND_SEND}
];

const getDocumentsForSending = (docs) => {
  let sequence = 1;
  return isEmpty(docs) ? [] : docs.filter(doc => doc.selected).map(doc => convertSendingDocument(sequence++, doc));
};

const convertSendingDocument = (sequence, {type, name, extension, size, lastModified, sourceId}) => ({
  sequence,
  type,
  name,
  extension,
  size,
  lastModified,
  sourceId
});

const getRecipientsForSending = (recs, hasDocuments, defaultRoles) => {
  let rs = [];
  let sequence = 1;
  const defRoles = JSON.parse(JSON.stringify(defaultRoles));
  if (!isEmpty(recs)) {
    let routingOrder = recs.reduce((ro, r) => r && r.routingOrder > ro ? r.routingOrder : ro, 0);
    rs = recs.map(r => {
      let rec = {...r};
      if (isValidRecipient(rec) && (!isEmpty(rec.templateId) || hasDocuments)) {
        rec.sequence = sequence++;
        if (!isEmpty(rec.routingOrder)) {
          rec.routingOrder = ++routingOrder;
        }
        rec.role = !isEmpty(rec.role) && !isEmpty(rec.role.name) ? rec.role : getNextRole(defRoles);
        delete rec.templateId;
        delete rec.locked;
        delete rec.original;
      }
      return rec;
    });
  }
  return rs;
};


const getNextRole = (defaultRoles) => {
  const firstKey = Object.keys(defaultRoles)[0];
  const nextRole = isEmpty(defaultRoles) ? null : defaultRoles[firstKey];
  if (!isEmpty(nextRole)) {
    delete defaultRoles[firstKey];
  }
  return nextRole;
};

const isValidRecipient = (recipient) => (
  !isEmpty(recipient) &&
  ((!isEmpty(recipient.name) &&
    !isEmpty(recipient.email)) ||
    (!isEmpty(recipient.signingGroup) &&
      !isEmpty(recipient.signingGroup.name))) &&
  (isEmpty(recipient.templateId) ||
    (!isEmpty(recipient.role) &&
      !isEmpty(recipient.role.name)))
);

export {
  LABEL,
  PROGRESS_STEP,
  OPERATION,
  MIN_STEP,
  MAX_STEP,
  STEPS,
  getDocumentsForSending,
  getRecipientsForSending

};