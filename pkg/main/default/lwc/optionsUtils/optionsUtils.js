import { format } from 'c/utils';

//custom labels
import options from '@salesforce/label/c.Options';
import optionsInfoText from '@salesforce/label/c.OptionsInfoText';
import helpVideoText from '@salesforce/label/c.DecOptionsVideoText';
import helpVideoLength from '@salesforce/label/c.DecOptionsVideoLength';
import helpVideoLink from '@salesforce/label/c.DecOptionsVideoLink';
import documentWriteback from '@salesforce/label/c.DocumentWriteback';
import stage from '@salesforce/label/c.Stage';
import reminders from '@salesforce/label/c.Reminders';
import automaticReminders from '@salesforce/label/c.AutomaticReminders';
import expiration from '@salesforce/label/c.Expiration';
import doNotRemind from '@salesforce/label/c.DoNotRemind';
import everyDay from '@salesforce/label/c.EveryDay';
import everyNumberOfDays from '@salesforce/label/c.EveryNumberOfDays';
import expiresAfterSending from '@salesforce/label/c.ExpiresAfterSending';
import documentWriteBackOptionMessage from '@salesforce/label/c.DocumentWriteBackOptionMessage';
import documentWriteBackCombineDocuments from '@salesforce/label/c.DocumentWriteBackCombineAllDocuments';
import documentWriteBackCertificateOfCompletion from '@salesforce/label/c.DocumentWriteBackCertificateOfCompletion';
import filename from '@salesforce/label/c.DocumentWriteBackFilename';
import documentName from '@salesforce/label/c.AgreementName';
import moreOptions from '@salesforce/label/c.MoreOptions';
import documentNameAndEnvelopeStatus from '@salesforce/label/c.DocumentNameAndEnvelopeStatus';
import emailSubject from '@salesforce/label/c.EmailSubject';
import documentNameAndPdf from '@salesforce/label/c.DocumentNameAndPdf';
import documentNameAndEnvelopeStatusAndPdf from '@salesforce/label/c.DocumentNameAndEnvelopeStatusAndPdf';
import emailSubjectAndEnvelopeStatus from '@salesforce/label/c.EmailSubjectAndEnvelopeStatus';
import envelopeAndEnvelopeIDAndPdf from '@salesforce/label/c.EnvelopeAndEnvelopeIDAndPdf';
import emailSubjectAndPdf from '@salesforce/label/c.EmailSubjectAndPdf';
import emailSubjectAndEnvelopeStatusAndPdf from '@salesforce/label/c.EmailSubjectAndEnvelopeStatusAndPdf';
import dataWriteback from '@salesforce/label/c.DataWriteback';
import dataWritebackHelpText from '@salesforce/label/c.DataWritebackHelpText';
import doNotUpdatePlaceholder from '@salesforce/label/c.DoNotUpdatePlaceholder';
import stageUpdate from '@salesforce/label/c.StageUpdate';
import expirationDateError from '@salesforce/label/c.ExpirationDateError';

const LABEL = {
  options,
  optionsInfoText,
  helpVideoText,
  helpVideoLength,
  helpVideoLink,
  documentWriteback,
  stage,
  reminders,
  automaticReminders,
  expiration,
  moreOptions,
  doNotRemind,
  everyDay,
  expiresAfterSending,
  everyNumberOfDays,
  documentWriteBackOptionMessage,
  documentWriteBackCombineDocuments,
  documentWriteBackCertificateOfCompletion,
  filename,
  dataWriteback,
  dataWritebackHelpText,
  doNotUpdatePlaceholder,
  stageUpdate,
  expirationDateError
};

const DEFAULT_EXPIRATION = 90;
const ENVELOPE_STATUS_COMPLETED = 'completed';

const REMINDER_OPTIONS = [
  {
    label: LABEL.doNotRemind,
    value: 0
  },
  {
    label: LABEL.everyDay,
    value: 1
  },
  {
    label: format(LABEL.everyNumberOfDays, 2),
    value: 2
  },
  {
    label: format(LABEL.everyNumberOfDays, 3),
    value: 3
  },
  {
    label: format(LABEL.everyNumberOfDays, 4),
    value: 4
  },
  {
    label: format(LABEL.everyNumberOfDays, 5),
    value: 5
  },
  {
    label: format(LABEL.everyNumberOfDays, 6),
    value: 6
  },
  {
    label: format(LABEL.everyNumberOfDays, 7),
    value: 7
  }
];

const getDefaultNotifications = () => ({
  remind: false,
  remindAfterDays: null,
  remindFrequencyDays: null,
  expires: false,
  expireAfterDays: null,
  expireWarnDays: null
});

const getDefaultOptions = () => {
  return {
    includeDefaultAutoPlaceTags: false,
    documentWriteBack: {
      linkedEntityId: null,
      nameFormat: null,
      combineDocuments: false,
      includeCertificateOfCompletion: false
    },
    envelopeEventUpdates: null,
    recipientEventUpdates: null
  };
}

const FILE_NAME_OPTIONS_DEFAULT = [
  { label: documentName, value: 'Name' },
  { label: documentNameAndEnvelopeStatus, value: 'NameEnvStatus' },
  { label: documentNameAndPdf, value: 'NamePDF' },
  { label: documentNameAndEnvelopeStatusAndPdf, value: 'NameEnvStatusPDF' }
];

const FILE_NAME_OPTIONS_COMBINED_DOCS = [
  { label: emailSubject, value: 'Name' },
  { label: emailSubjectAndEnvelopeStatus, value: 'NameEnvStatus' },
  { label: emailSubjectAndPdf, value: 'NamePDF'},
  { label: emailSubjectAndEnvelopeStatusAndPdf, value: 'NameEnvStatusPDF' },
  { label: envelopeAndEnvelopeIDAndPdf, value: 'EnvelopePDF' }
 ];

export {
  LABEL,
  DEFAULT_EXPIRATION,
  REMINDER_OPTIONS,
  FILE_NAME_OPTIONS_DEFAULT,
  FILE_NAME_OPTIONS_COMBINED_DOCS,
  ENVELOPE_STATUS_COMPLETED,
  getDefaultNotifications,
  getDefaultOptions
}