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

const DOCUMENT_TYPE_TEMPLATE_DOCUMENT = 'TemplateDocument';
const DOCUMENT_TYPE_SOURCE_FILES = 'SourceFiles';
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
  deleteDocument
};

const TEMPLATE_DOCUMENT_ACTIONS = [
  {
    label: LABEL.previewDocument,
    value: 'preview'
  },
  {
    label: LABEL.renameDocument,
    value: 'rename'
  },
  {
    label: LABEL.deleteDocument,
    value: 'delete'
  }
];

const SOURCE_FILES_TYPES = {
  LATEST: 'latest',
  CONTAINS: 'contains',
  ALL: 'all'
};

const getDefaultSourceFiles = (sequence = 2) => {
  return {
    id: DOCUMENT_TYPE_SOURCE_FILES, // placeholder ID to bypass null ID error on rendering
    type: DOCUMENT_TYPE_SOURCE_FILES,
    filter: {
      filterBy: '',
      orderBy: 'CreatedDate DESC',
      maximumRecords: 1
    },
    sequence,
    readOnly: true,
    required: false
  };
}

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
}

export {
  DOCUMENT_TYPE_SOURCE_FILES,
  DOCUMENT_TYPE_TEMPLATE_DOCUMENT,
  LABEL,
  getDefaultSourceFiles,
  getDefaultTemplateDocument,
  SOURCE_FILES_TYPES,
  TEMPLATE_DOCUMENT_ACTIONS
}