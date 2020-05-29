import {LightningElement, api} from 'lwc';
import {formatFileSize} from 'c/utils';
import {LABEL, TEMPLATE_DOCUMENT_ACTIONS} from 'c/documentUtils';

// Lightning message service
import {createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
// Publisher
import DEC_DELETE_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecDeleteTemplateDocument__c';

export default class DecTemplateDocument extends LightningElement {
  @api document;
  @api index;
  context = createMessageContext();

  label = LABEL;
  templateDocumentActions = TEMPLATE_DOCUMENT_ACTIONS;

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get fileSize() {
    return formatFileSize(this.document.size, 0);
  }

  previewFile() {
    window.open('/' + this.document.sourceId, '_blank');
  }

  handleFileOption(event) {
    var action = event.detail.value;

    switch (action) {
      case 'preview':
        this.previewFile();
        break;
      case 'rename':
        break;
      case 'delete':
        this.deleteTemplateDocument();
        break;
      default:
        break;
    }
  }

  deleteTemplateDocument() {
    const message = {
      contentDocumentId: this.document.sourceId,
      index: this.index
    };
    publish(this.context, DEC_DELETE_TEMPLATE_DOCUMENT, message);
  }
}