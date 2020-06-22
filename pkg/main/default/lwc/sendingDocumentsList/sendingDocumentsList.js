import { LightningElement, api } from 'lwc';

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
import { isEmpty, format, formatFileSize } from 'c/utils';
import { LABEL } from 'c/documentUtils';

export default class SendingDocumentsList extends LightningElement {
    @api recordId;
    @api documents;
    @api forbidEnvelopeChanges;

    label = LABEL;

    context = createMessageContext();

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    get selectedDocumentsHeader() {
        const selectedDocuments = isEmpty(this.documents) ? 0 : this.documents.filter(doc => doc.selected).length;
        return format(this.label.selectedDocuments, selectedDocuments);
    }

    get allDocumentsSelected() {
        return !isEmpty(this.documents) && isEmpty(this.documents.find(doc => !doc.selected));
    }

    addUploadedDocument(event) {
        getLinkedDocuments({
            sourceId: this.recordId
        })
        .then(docs => {
            const uploadedDocument = docs.find(doc => doc.sourceId === event.detail.data.Id);
            if (!isEmpty(uploadedDocument)) {
                const newDocument = this.addDocumentProperties(uploadedDocument, true);
                this.addNewDocument(newDocument);
            }
        })
        .catch(error => {
            if (!isEmpty(error.body)) {
                this.showError(error.body.message);
            }
        });
    }

    addDocumentProperties(doc, selected) {
        if (doc) {
            return {
                ... doc,
                selected: selected,
                formattedSize: doc.size ? formatFileSize(doc.size) : '',
                formattedLastModified: doc.lastModified ? new Date(doc.lastModified).toLocaleString() : ''
            };
        }
        return doc;
    }

    toggleAllDocuments(event) {
        publish(this.context, SENDING_TOGGLE_DOCUMENT_SELECTION, { selected: event.target.checked });
    }

    addNewDocument(document) {
        publish(this.context, SENDING_ADD_DOCUMENT, { document });
    }

    showError(errorMessage) {
        publish(this.context, ERROR, { errorMessage });
    }
}