import {LightningElement, api} from 'lwc';
import {isEmpty, formatFileSize, format} from 'c/utils';
import {LABEL, TEMPLATE_DOCUMENT_ACTIONS, DOCUMENT_TYPE_CONTENT_VERSION} from 'c/documentUtils';
import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';

// Lightning message service
import {
    createMessageContext,
    releaseMessageContext,
    publish
  } from 'lightning/messageService';

export default class SendingDocument extends LightningElement {
    @api document;
    @api index;
    @api forbidEnvelopeChanges;

    context = createMessageContext();

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    label = LABEL;
    templateDocumentActions = TEMPLATE_DOCUMENT_ACTIONS;

    get canPreview() {
        return this.document.type === DOCUMENT_TYPE_CONTENT_VERSION && !isEmpty(this.document.sourceId);
    }

    get details() {
        const formattedSize = isEmpty(this.document.size) ? null : formatFileSize(this.document.size, 0);
        return isEmpty(formattedSize) ? this.document.extension : format('{0} {1} {2}', formattedSize, '•', this.document.extension);
    }

    previewFile() {
        window.open('/' + this.document.sourceId, '_blank');
    }

    toggleDocumentSelection(event) {
        publish(this.context, SENDING_TOGGLE_DOCUMENT_SELECTION, {
            selected: event.target.checked,
            index: this.index
        });
    }
}