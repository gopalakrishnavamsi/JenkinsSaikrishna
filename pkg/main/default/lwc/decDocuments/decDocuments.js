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
// Lightning message service
import {createMessageContext,
        releaseMessageContext,
        APPLICATION_SCOPE,
        subscribe} from 'lightning/messageService';
// Subscriber
import DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP from '@salesforce/messageChannel/DecUpdateDocumentOnDragAndDrop__c';

export default class DecDocuments extends LightningElement {
  @api recordId;
  @api documents;
  @api attachSourceFiles;
  records;
  hideTemplateFileUpload = false;
  sourceFilesDocument = null;
  addDocumentsEmptyImageURL = `${ADD_DOCUMENTS_EMPTY_IMAGE}#decAddDocumentsEmpty`;
  label = LABEL;
  context = createMessageContext();

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get hasTemplateDocuments() {
    return !isEmpty(this.getDocumentType(DOCUMENT_TYPE_TEMPLATE_DOCUMENT));
  }

  getDocumentType(type) {
    return !isEmpty(this.documents) && this.documents.find((doc) => doc.type === type);
  }

  handleFileUploadSuccess(event) {
    const newTemplateDocument = getDefaultTemplateDocument(1, event.detail.data);
    genericEvent('updatetemplatedocuments', {...newTemplateDocument, size:event.detail.data.ContentSize}, this, true);
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

  subscribeToMessageChannel() {
    if(this.subscription) {
      return;
    }
    this.subscription = subscribe(this.context, DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP, (message) => {
      this.updateDocument(message);
    }, {scope: APPLICATION_SCOPE});
  }

  updateDocumentsEvent(event) {
    this.updateDocuments(event.detail.documents);
  }

  updateDocuments(docs) {
      genericEvent('update', docs, this, true);
  }

  // Called by decDocument for modifying inner document details
  updateDocument(message) {
    let docs = this.documents.slice();
    docs[message.index] = message.document;
    this.updateDocuments(docs);
  }

  handleClearTemplateDocument() {
    this.hideTemplateFileUpload = true;
  }
}
