import { LightningElement, api } from 'lwc';
import {
    createMessageContext,
    releaseMessageContext
  } from 'lightning/messageService';
//Subscriber
import SENDING_RENAME_DOCUMENT from '@salesforce/messageChannel/SendingRenameDocument__c';
import SENDING_REMOVE_DOCUMENT from '@salesforce/messageChannel/SendingRemoveDocument__c';
import SENDING_UPDATE_DOCUMENTS from '@salesforce/messageChannel/SendingUpdateDocuments__c';
import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';
import {isEmpty, proxify, subscribeToMessageChannel} from 'c/utils';
import { DOCUMENT_TYPE_TEMPLATE } from 'c/documentUtils';

export default class SendingDocuments extends LightningElement {
    @api recordId;
    @api envelopeId;
    @api forbidEnvelopeChanges;

    privateDocuments = [];

    context = createMessageContext();

    @api
    fetchDocuments() {
      return {'data': this.privateDocuments};
    }

    @api
    get documents() {
      return this.privateDocuments;
    }
  
    set documents(docs) {
      this.privateDocuments = isEmpty(docs) ? null : proxify(docs);
    }

    connectedCallback() {
        this.toggleDocSelectionSubscription = subscribeToMessageChannel(
            this.context,
            this.toggleDocSelectionSubscription,
            SENDING_TOGGLE_DOCUMENT_SELECTION,
            this.toggleDocumentSelection.bind(this)
        );
    
        this.addNewDocumentSubscription = subscribeToMessageChannel(
            this.context,
            this.addNewDocumentSubscription,
            SENDING_UPDATE_DOCUMENTS,
            this.updateDocuments.bind(this)
        );

        this.sendingRenameDocumentSubscription = subscribeToMessageChannel(
          this.context,
          this.sendingRenameDocumentSubscription,
          SENDING_RENAME_DOCUMENT,
          this.handleRenameDocument.bind(this)
        );

        this.sendingRemoveDocumentSubscription = subscribeToMessageChannel(
          this.context,
          this.sendingRemoveDocumentSubscription,
          SENDING_REMOVE_DOCUMENT,
          this.handleRemoveDocument.bind(this)
        );
    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    // Toggle a single document or all documents based on presence of a message index
    toggleDocumentSelection(message) {
        const toggleSingleDocument = !isEmpty(message.index);
        this.privateDocuments = this.privateDocuments.map((doc, index) => {
            // Docs forbidden changes (online editor templates) and envelope templates may not be toggled
            const isDocumentLocked = this.forbidEnvelopeChanges || doc.type === DOCUMENT_TYPE_TEMPLATE;
            if (!isDocumentLocked && ((toggleSingleDocument && index === message.index) || !toggleSingleDocument)) {
                return {
                    ...doc,
                    selected: message.selected
                };
            }
            return doc;
        });
    }

    updateDocuments(message) {
        this.privateDocuments = message.documents;
    }

    handleRenameDocument(message) {
        const documentName = message.name;
        const documentIndex = message.index;
        const docs = this.privateDocuments.map((d, i) => {
            if (i === documentIndex) {
                return {...d, name: documentName};
            }
            return d;
        });
        this.privateDocuments = docs;
    }

    handleRemoveDocument(message) {
        const documents = this.privateDocuments.filter((d, i) => i !== message.index);
        this.privateDocuments = documents;
    }
}