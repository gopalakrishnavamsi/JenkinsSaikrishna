import { format } from 'c/utils';

//custom labels
import options from '@salesforce/label/c.Options';
import optionsInfoText from '@salesforce/label/c.OptionsInfoText';
import helpVideoText from '@salesforce/label/c.DecOptionsVideoText';
import helpVideoLength from '@salesforce/label/c.DecOptionsVideoLength';
import helpVideoLink from '@salesforce/label/c.DecOptionsVideoLink';
import documentWriteback from '@salesforce/label/c.DocumentWriteback';
import opportunityStage from '@salesforce/label/c.OpportunityStage';
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
import documentNameAndEnvelopeStatus from '@salesforce/label/c.DocumentNameAndEnvelopeStatus';
import emailSubject from '@salesforce/label/c.EmailSubject';
import documentNameAndPdf from '@salesforce/label/c.DocumentNameAndPdf';
import documentNameAndEnvelopeStatusAndPdf from '@salesforce/label/c.DocumentNameAndEnvelopeStatusAndPdf';
import emailSubjectAndEnvelopeStatus from '@salesforce/label/c.EmailSubjectAndEnvelopeStatus';
import envelopeAndEnvelopeIDAndPdf from '@salesforce/label/c.EnvelopeAndEnvelopeIDAndPdf';
import emailSubjectAndPdf from '@salesforce/label/c.EmailSubjectAndPdf';
import emailSubjectAndEnvelopeStatusAndPdf from '@salesforce/label/c.EmailSubjectAndEnvelopeStatusAndPdf';

const LABEL = {
  options,
  optionsInfoText,
  helpVideoText,
  helpVideoLength,
  helpVideoLink,
  documentWriteback,
  opportunityStage,
  reminders,
  automaticReminders,
  expiration,
  doNotRemind,
  everyDay,
  everyNumberOfDays,
  expiresAfterSending,
  documentWriteBackOptionMessage,
  documentWriteBackCombineDocuments,
  documentWriteBackCertificateOfCompletion,
  filename
};

const DEFAULT_EXPIRATION = 90;

const REMINDER_OPTIONS = [
  {
    label: LABEL.doNotRemind,
    value: ''
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
  getDefaultNotifications,
  getDefaultOptions
}