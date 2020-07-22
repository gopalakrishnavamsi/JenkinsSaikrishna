import envelopeConfiguration from '@salesforce/label/c.EnvelopeTemplateUpperCase';
import documents from '@salesforce/label/c.Documents';
import recipients from '@salesforce/label/c.Recipients';
import mergeFields from '@salesforce/label/c.MergeFields';
import tagger from '@salesforce/label/c.Tagger';
import options from '@salesforce/label/c.Options';
import customButton from '@salesforce/label/c.PublishStep';
import errorLabel from '@salesforce/label/c.Error';
import nameLabel from '@salesforce/label/c.NameLabel';
import renameEnvelopeConfiguration from '@salesforce/label/c.RenameEnvelopeConfiguration';
import saveAndClose from '@salesforce/label/c.SaveAndClose';
import saveAndFinish from '@salesforce/label/c.SaveAndFinish';
import back from '@salesforce/label/c.Back';
import next from '@salesforce/label/c.Next';
import save from '@salesforce/label/c.Save';
import cancel from '@salesforce/label/c.Cancel';
import defaultEmailSubject from '@salesforce/label/c.DefaultEmailSubject';
import defaultEmailMessage from '@salesforce/label/c.DefaultEmailMessage';

const LABEL = {
  envelopeConfiguration,
  documents,
  recipients,
  mergeFields,
  tagger,
  options,
  customButton,
  errorLabel,
  nameLabel,
  renameEnvelopeConfiguration,
  saveAndClose,
  saveAndFinish,
  back,
  next,
  save,
  cancel,
  defaultEmailSubject,
  defaultEmailMessage
};

// TODO: Merge Fields step to be returned in eSign Phase 2 between Recipients and Tagger steps
const PROGRESS_STEP = {
  DOCUMENTS: '1',
  RECIPIENTS: '2',
  TAGGER: '3',
  OPTIONS: '4',
  CUSTOM_BUTTON: '5'
};

const OPERATION = {
  BACK: 'back',
  NEXT: 'next'
};

const MAX_STEP = PROGRESS_STEP.CUSTOM_BUTTON;
const MIN_STEP = PROGRESS_STEP.DOCUMENTS;

const STEPS = [
  {'label': LABEL.documents, 'value': PROGRESS_STEP.DOCUMENTS, 'disabled': false},
  {'label': LABEL.recipients, 'value': PROGRESS_STEP.RECIPIENTS, 'disabled': false},
  {'label': LABEL.tagger, 'value': PROGRESS_STEP.TAGGER, 'disabled': false},
  {'label': LABEL.options, 'value': PROGRESS_STEP.OPTIONS, 'disabled': false},
  {'label': LABEL.customButton, 'value': PROGRESS_STEP.CUSTOM_BUTTON, 'disabled': false}];

export {
  LABEL,
  PROGRESS_STEP,
  OPERATION,
  MAX_STEP,
  MIN_STEP,
  STEPS
};