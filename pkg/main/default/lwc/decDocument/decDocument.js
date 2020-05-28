import { LightningElement, api } from 'lwc';

// utility functions
import {isEmpty} from 'c/utils';
import { DOCUMENT_TYPE_TEMPLATE_DOCUMENT, DOCUMENT_TYPE_SOURCE_FILES } from 'c/documentUtils';

// Lightning message service - Publisher
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP from '@salesforce/messageChannel/DecUpdateDocumentOnDragAndDrop__c';

export default class DecDocument extends LightningElement {
    @api
    document;

    @api
    index;

    @api
    attachSourceFiles;

    context = createMessageContext();

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    get isTemplateDocument() {
        return isEmpty(this.document) ? false :
          this.document.type === DOCUMENT_TYPE_TEMPLATE_DOCUMENT;
    }

    get isSourceFiles() {
        return isEmpty(this.document) ? false :
          this.document.type === DOCUMENT_TYPE_SOURCE_FILES;
    }

    updateDocument(event) {
        const message = {
            document: event.detail.data.document,
            index: event.detail.data.index
        };
        publish(this.context, DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP, message);
    } 
}