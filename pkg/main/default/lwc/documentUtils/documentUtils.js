//custom labels
import addDocuments from '@salesforce/label/c.AddDocuments';
import documents from '@salesforce/label/c.Documents';
import addDocumentsHelpText from '@salesforce/label/c.AddDocumentsHelpText';
import addDocumentsInfoText from '@salesforce/label/c.AddDocumentsInfoText';
import upload from '@salesforce/label/c.Upload';
import uploadDocument from '@salesforce/label/c.UploadDocument';
import dropDocuments from '@salesforce/label/c.DropDocuments';
import helpVideoText from '@salesforce/label/c.DecDocumentsVideoText';
import helpVideoLength from '@salesforce/label/c.DecDocumentsVideoLength';
import helpVideoLink from '@salesforce/label/c.DecDocumentsVideoLink';
import moreActions from '@salesforce/label/c.MoreActions';
import attachDocuments from '@salesforce/label/c.AttachDocuments';
import documentSelection from '@salesforce/label/c.DocumentSelection';
import latestDocument from '@salesforce/label/c.LatestDocument';
import fileNameContainsPending from '@salesforce/label/c.FileNameContainsPending';
import fileNameContains from '@salesforce/label/c.FileNameContains';
import allDocuments from '@salesforce/label/c.AllDocuments';
import previewDocument from '@salesforce/label/c.PreviewStep';
import renameDocument from '@salesforce/label/c.Rename';
import deleteDocument from '@salesforce/label/c.DeleteButtonLabel';
import cancel from '@salesforce/label/c.Cancel';
import renameModalTitle from '@salesforce/label/c.RenameAgreement';
import selectedDocuments from '@salesforce/label/c.SelectedDocuments';
import addFromSalesforce from '@salesforce/label/c.AddFromSalesforce';

// DEC experience
const DOCUMENT_TYPE_TEMPLATE_DOCUMENT = 'TemplateDocument';
const DOCUMENT_TYPE_SOURCE_FILES = 'SourceFiles';

// Sending experience
const DOCUMENT_TYPE_CONTENT_VERSION = 'ContentVersion';
const DOCUMENT_TYPE_TEMPLATE = 'Template';

const LABEL = {
  addDocuments,
  documents,
  addDocumentsHelpText,
  addDocumentsInfoText,
  upload,
  uploadDocument,
  dropDocuments,
  helpVideoText,
  helpVideoLength,
  helpVideoLink,
  moreActions,
  attachDocuments,
  documentSelection,
  latestDocument,
  fileNameContainsPending,
  fileNameContains,
  allDocuments,
  previewDocument,
  renameDocument,
  deleteDocument,
  cancel,
  renameModalTitle,
  selectedDocuments,
  addFromSalesforce
};

const TEMPLATE_DOCUMENT_ACTIONS = [
  {
    label: LABEL.previewDocument,
    value: 'preview'
  },
  {
    label: LABEL.renameDocument,
    value: 'rename'
  }
];

const TEMPLATE_DOCUMENT_DELETE_ACTION = {
  label: LABEL.deleteDocument,
  value: 'delete'
};

const SOURCE_FILES_TYPES = {
  LATEST: 'latest',
  CONTAINS: 'contains',
  ALL: 'all'
};

const SOURCE_FILES_MENU_OPTIONS = [
  {
    label: LABEL.latestDocument,
    value: SOURCE_FILES_TYPES.LATEST
  },
  {
    label: LABEL.fileNameContainsPending,
    value: SOURCE_FILES_TYPES.CONTAINS
  },
  {
    label: LABEL.allDocuments,
    value: SOURCE_FILES_TYPES.ALL
  }
];

const LATEST_SOURCE_FILES_ORDER_BY = 'ContentDocument.LatestPublishedVersion.LastModifiedDate DESC';
const FILE_NAME_FILTER_PREFIX = 'ContentDocument.Title LIKE \'%';
const FILE_NAME_FILTER_SUFFIX = '%\'';
const FILE_NAME_CONTAINS_ORDER_BY = 'ContentDocument.Title ASC';

const getDefaultSourceFiles = (sequence = 2) => {
  return {
    id: DOCUMENT_TYPE_SOURCE_FILES, // placeholder ID to bypass null ID error on rendering
    type: DOCUMENT_TYPE_SOURCE_FILES,
    filter: {
      filterBy: '',
      orderBy: LATEST_SOURCE_FILES_ORDER_BY,
      maximumRecords: 1
    },
    sequence,
    readOnly: true,
    required: false
  };
};

const getDefaultTemplateDocument = (sequence = 1, contentVersion) => {
  return {
    id: contentVersion.id, // placeholder ID to bypass null ID error on rendering
    type: DOCUMENT_TYPE_TEMPLATE_DOCUMENT,
    sourceId: contentVersion.ContentDocumentId,
    sequence,
    name: contentVersion.Title,
    extension: contentVersion.FileExtension,
    readOnly: true,
    required: false
  };
};

export {
  DOCUMENT_TYPE_SOURCE_FILES,
  DOCUMENT_TYPE_TEMPLATE_DOCUMENT,
  DOCUMENT_TYPE_CONTENT_VERSION,
  DOCUMENT_TYPE_TEMPLATE,
  LABEL,
  getDefaultSourceFiles,
  getDefaultTemplateDocument,
  SOURCE_FILES_TYPES,
  SOURCE_FILES_MENU_OPTIONS,
  TEMPLATE_DOCUMENT_ACTIONS,
  TEMPLATE_DOCUMENT_DELETE_ACTION,
  LATEST_SOURCE_FILES_ORDER_BY,
  FILE_NAME_FILTER_PREFIX,
  FILE_NAME_FILTER_SUFFIX,
  FILE_NAME_CONTAINS_ORDER_BY
};