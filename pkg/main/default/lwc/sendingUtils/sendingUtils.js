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
  {'label': LABEL.documents, 'value': PROGRESS_STEP.DOCUMENTS, 'disabled': false},
  {'label': LABEL.recipients, 'value': PROGRESS_STEP.RECIPIENTS, 'disabled': false},
  {'label': LABEL.prepareAndSend, 'value': PROGRESS_STEP.PREPARE_AND_SEND, 'disabled': false}
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

export {
  LABEL,
  PROGRESS_STEP,
  OPERATION,
  MIN_STEP,
  MAX_STEP,
  STEPS,
  getDocumentsForSending
};