import {LightningElement, api} from 'lwc';
//static resource
import ADD_DOCUMENTS_EMPTY_IMAGE from '@salesforce/resourceUrl/DecAddDocumentsEmpty';
//utils
import {genericEvent, isEmpty} from 'c/utils';
import {
  DOCUMENT_TYPE_TEMPLATE_DOCUMENT,
  DOCUMENT_TYPE_SOURCE_FILES,
  LABEL,
  getDefaultTemplateDocument,
  getDefaultSourceFiles
} from 'c/documentUtils';

export default class DecDocuments extends LightningElement {
  @api recordId;
  @api documents;
  @api attachSourceFiles;
  records;
  hideTemplateFileUpload = false;
  addDocumentsEmptyImageURL = `${ADD_DOCUMENTS_EMPTY_IMAGE}#decAddDocumentsEmpty`;
  label = LABEL;

  get hasTemplateDocuments() {
    return !isEmpty(this.getDocumentType(DOCUMENT_TYPE_TEMPLATE_DOCUMENT));
  }

  getDocumentType(type) {
    return !isEmpty(this.documents) && this.documents.find((doc) => doc.type === type);
  }

  handleFileUploadSuccess(event) {
    const newTemplateDocument = getDefaultTemplateDocument(1, event.detail.data);
    genericEvent.call(this, 'updatetemplatedocuments', {
      ...newTemplateDocument,
      size: event.detail.data.ContentSize
    }, true);
  }

  renderedCallback() {
    let sourceFilesDoc = this.getDocumentType(DOCUMENT_TYPE_SOURCE_FILES);
    if (isEmpty(sourceFilesDoc)) {
      sourceFilesDoc = getDefaultSourceFiles();
      this.updateDocuments([...this.documents, sourceFilesDoc], false);
    }
  }

  updateDocumentsEvent(event) {
    this.updateDocuments(event.detail.documents, true);
  }

  updateDocuments(documents, isDirty) {
    genericEvent.call(this, 'update', {documents, isDirty}, true);
  }

  handleClearTemplateDocument() {
    this.hideTemplateFileUpload = true;
  }

  handleFileOnDrop(event) {
    event.preventDefault();
    if (event.dataTransfer.files.length > 0) {
      const fileUploadComponent = this.template.querySelector('c-file-upload');
      fileUploadComponent.handleFileUploadFromDragAndDrop(event.dataTransfer.files[0]);
    }
  }

  handleFileOnDragOver(event) {
    event.stopPropagation();
    event.preventDefault();
  }

  handleFileOnDragEnter(event) {
    event.stopPropagation();
    event.preventDefault();
  }
}
