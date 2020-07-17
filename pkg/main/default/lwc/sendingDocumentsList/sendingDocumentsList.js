import {LightningElement, api} from 'lwc';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
import ERROR from '@salesforce/messageChannel/Error__c';
import SENDING_ADD_DOCUMENT from '@salesforce/messageChannel/SendingAddDocument__c';
import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';

//apex methods
import getLinkedDocuments from '@salesforce/apex/SendingController.getLinkedDocuments';

// utility functions
import {isEmpty, format, formatFileSize} from 'c/utils';
import {LABEL} from 'c/documentUtils';

export default class SendingDocumentsList extends LightningElement {
  @api recordId;
  @api envelopeId;
  documents;
  @api forbidEnvelopeChanges;
  isLoading = false;

  label = LABEL;

  context = createMessageContext();

  @api
  get docs() {
    return this.documents;
  }

  set docs(value) {
    this.documents = value.filter(doc =>
      !isEmpty(doc) &&
      !isEmpty(doc.sourceId));
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get selectedDocumentsHeader() {
    let selectedDocuments = 0;
    if (!isEmpty(this.documents)) {
      this.documents.filter(doc =>
        !isEmpty(doc) &&
        !isEmpty(doc.selected) &&
        doc.selected &&
        !isEmpty(doc.isEmptyTemplate) &&
        !doc.isEmptyTemplate).length;
    }
    return format(this.label.selectedDocuments, selectedDocuments);
  }

  get allDocumentsSelected() {
    return !isEmpty(this.documents) &&
      this.documents.length > 0 &&
      isEmpty(this.documents.find(doc =>
        !isEmpty(doc) &&
        (!isEmpty(doc.selected) && !doc.selected) ||
        (!isEmpty(doc.isEmptyTemplate) && doc.isEmptyTemplate)));
  }

  handleOnFileUpload(event) {
    let selectedDocId = event.detail.data.Id;
    this.addToDoc(selectedDocId);
  }

  addToDoc(selectedContentIds) {
    if (isEmpty(selectedContentIds)) {
      return;
    }
    let docIds = [];
    docIds.push(selectedContentIds);
    this.addUploadedDocument(docIds);
  }

  handleOnFileUploadFromModal(event) {
    let selectedDocIds = event.detail.data;
    this.addToDoc(selectedDocIds);
  }

  addUploadedDocument(docIds) {
    this.setLoading(true);
    getLinkedDocuments({
      sourceId: this.envelopeId
    })
      .then(docs => {
        let selectedContentDocIds = docIds;
        let selectedDocs = [];
        for (let i = 0; i < selectedContentDocIds.length; i++) {
          let uploadedDocument = docs.find(doc => (!isEmpty(doc) && !isEmpty(doc.sourceId) && doc.sourceId === selectedContentDocIds[i]));
          if (!isEmpty(uploadedDocument)) {
            selectedDocs.push(uploadedDocument);
          }
        }
        if (!isEmpty(selectedDocs) && selectedDocs.length > 0) {
          for (let i = 0; i < selectedDocs.length; i++) {
            let newDocument = this.addDocumentProperties(selectedDocs[i], true);
            this.addNewDocument(newDocument);
          }
        }
        this.setLoading(false);
      })
      .catch(error => {
        if (!isEmpty(error.body)) {
          this.showError(error.body.message);
        }
        this.setLoading(false);
      });
  }

  addDocumentProperties(doc, selected) {
    if (doc) {
      return {
        ...doc,
        selected: selected,
        formattedSize: doc.size ? formatFileSize(doc.size) : '',
        formattedLastModified: doc.lastModified ? new Date(doc.lastModified).toLocaleString() : ''
      };
    }
    return doc;
  }

  toggleAllDocuments(event) {
    publish(this.context, SENDING_TOGGLE_DOCUMENT_SELECTION, {selected: event.target.checked});
  }

  addNewDocument(document) {
    let docs = [];
    docs.push(document);
    const message = {
      documents: docs
    };
    publish(this.context, SENDING_ADD_DOCUMENT, message);
  }

  showError(errorMessage) {
    publish(this.context, ERROR, {errorMessage});
  }

  handleAddFromSalesforce() {
    const selectFilesModalComponent = this.template.querySelector('c-select-files-modal');
    selectFilesModalComponent.handleShow();
  }

  handleOnSuccessFromSelectFilesModal(event) {
    this.addUploadedDocument(event.detail.data);
  }

  setLoading(value) {
    this.isLoading = value;
  }
}
