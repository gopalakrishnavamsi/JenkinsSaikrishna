import {LightningElement, api} from 'lwc';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
import ERROR from '@salesforce/messageChannel/Error__c';
import SENDING_UPDATE_DOCUMENTS from '@salesforce/messageChannel/SendingUpdateDocuments__c';
import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';

//apex methods
import getContentDocumentsById from '@salesforce/apex/SendingController.getContentDocumentsById';

// utility functions
import {isEmpty, format, formatFileSize} from 'c/utils';
import {LABEL} from 'c/documentUtils';
import {
  handleDragEnter,
  handleDragOver,
  handleDragLeave,
  handleDrop,
  itemDragStart,
  itemDragEnd
} from 'c/dragUtils';

export default class SendingDocumentsList extends LightningElement {
  @api recordId;
  @api envelopeId;
  @api forbidEnvelopeChanges;
  isLoading = false;

  label = LABEL;

  context = createMessageContext();

  documents = null;

  fromIndex = null;

  @api
  get docs() {
    return this.documents;
  }

  // For drag-and-drop functionality
  @api
  get list() {
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
    const selectedDocuments = !isEmpty(this.documents) ? this.documents.filter(doc => doc.selected).length : 0;
    return format(this.label.selectedDocuments, selectedDocuments);
  }

  get allDocumentsSelected() {
    if (isEmpty(this.documents)) return false;
    const hasEmptyTemplate = !isEmpty(this.documents.find(doc => doc.isEmptyTemplate));
    const filteredDocuments = hasEmptyTemplate ? this.documents.filter(doc => !doc.isEmptyTemplate) : this.documents;
    return isEmpty(filteredDocuments.find(doc => !doc.selected));
  }

  handleOnFileUpload(event) {
    let selectedDocId = event.detail.data.ContentDocumentId;
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
    getContentDocumentsById({
      contentDocumentIds: docIds
    })
      .then(docs => {
        if (!isEmpty(docs) && docs.length > 0) {
          this.addNewDocuments(docs.map(d => this.addDocumentProperties(d, true)));
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

  addNewDocuments(newDocuments) {
    this.updateDocuments(this.documents.concat(newDocuments));
  }

  updateDocuments(documents) {
    publish(this.context, SENDING_UPDATE_DOCUMENTS, { documents });
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

  /* Drag-and-drop functions */

  handleDragEnter(evt) {
    handleDragEnter(this, evt);
  }

  handleDragOver(evt) {
    handleDragOver(this, evt);
  }

  handleDragLeave(evt) {
    handleDragLeave(this, evt);
  }

  itemDragStart(evt) {
    itemDragStart(this, evt.currentTarget.dataset.id);
  }

  itemDragEnd(evt) {
    itemDragEnd(this, evt.currentTarget.dataset.id);
  }

  handleDrop(evt) {
    handleDrop(this, evt, this.updateDocuments.bind(this));
  }
}
