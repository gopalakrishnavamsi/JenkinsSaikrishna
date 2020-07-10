import {LightningElement, api} from 'lwc';
//static resource
import ADD_DOCUMENTS_EMPTY_IMAGE from '@salesforce/resourceUrl/DecAddDocumentsEmpty';
//utils
import {genericEvent, isEmpty} from 'c/utils';
import {DOCUMENT_TYPE_TEMPLATE_DOCUMENT, 
        DOCUMENT_TYPE_SOURCE_FILES,
        LABEL,
        getDefaultTemplateDocument,
        getDefaultSourceFiles} from 'c/documentUtils';

export default class DecDocuments extends LightningElement {
  @api recordId;
  @api documents;
  @api attachSourceFiles;
  records;
  hideTemplateFileUpload = false;
  sourceFilesDocument = null;
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
    genericEvent.call(this, 'updatetemplatedocuments', {...newTemplateDocument, size:event.detail.data.ContentSize}, true);
  }

  renderedCallback() {
    let sourceFilesDoc = this.getDocumentType(DOCUMENT_TYPE_SOURCE_FILES);
    const templateDoc = this.getDocumentType(DOCUMENT_TYPE_TEMPLATE_DOCUMENT);
    if (isEmpty(sourceFilesDoc)) {
      const sequence = isEmpty(templateDoc) ? 2 : this.documents.length + 1;

      if (isEmpty(this.sourceFilesDocument)) {
        sourceFilesDoc = getDefaultSourceFiles(sequence);
        this.sourceFilesDocument = sourceFilesDoc;
      } else {
        this.sourceFilesDocument = {
          ... this.sourceFilesDocument,
          sequence
        };
        sourceFilesDoc = this.sourceFilesDocument;
      }
      
      this.updateDocuments([...this.documents, sourceFilesDoc]);
    } else if (isEmpty(this.sourceFilesDocument) || sourceFilesDoc.id !== this.sourceFilesDocument.id) {
      this.sourceFilesDocument = sourceFilesDoc;
    }
  }

  updateDocumentsEvent(event) {
    this.updateDocuments(event.detail.documents);
  }

  updateDocuments(docs) {
      genericEvent.call(this, 'update', docs, true);
  }

  handleClearTemplateDocument() {
    this.hideTemplateFileUpload = true;
  }
}
