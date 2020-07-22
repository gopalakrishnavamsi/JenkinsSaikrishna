import { LightningElement, api } from 'lwc';
import {
    createMessageContext,
    releaseMessageContext
  } from 'lightning/messageService';
  import SENDING_UPDATE_DOCUMENTS from '@salesforce/messageChannel/SendingUpdateDocuments__c';
  import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';
import {isEmpty, proxify, subscribeToMessageChannel} from 'c/utils';

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
    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    // Toggle a single document or all documents based on presence of a message index
    toggleDocumentSelection(message) {
        const toggleSingleDocument = !isEmpty(message.index);
        this.privateDocuments = this.privateDocuments.map((doc, index) => {
        if ((toggleSingleDocument && index === message.index) || (!toggleSingleDocument) && !doc.isEmptyTemplate) {
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
}