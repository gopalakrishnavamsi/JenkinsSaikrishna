import {LightningElement, api} from 'lwc';
import {isEmpty, format, formatFileSize} from 'c/utils';
import {LABEL, TEMPLATE_DOCUMENT_ACTIONS} from 'c/documentUtils';

// Lightning message service
import {createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
// Publisher
import DEC_RENAME_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecRenameTemplateDocument__c';
import DEC_DELETE_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecDeleteTemplateDocument__c';

export default class DecTemplateDocument extends LightningElement {
  @api document;
  @api index;

  showRenameModal = false;
  documentNameCopy = null;
  context = createMessageContext();

  label = LABEL;
  templateDocumentActions = TEMPLATE_DOCUMENT_ACTIONS;

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get fileSize() {
    return formatFileSize(this.document.size, 0);
  }

  get disableModalSave() {
    return isEmpty(this.documentNameCopy) || this.documentNameCopy.trim().length === 0;
  }

  openRenameModal() {
    const docName = this.document.name;
    this.documentNameCopy = docName.substring(0, docName.lastIndexOf('.'));
    this.showRenameModal = true;
  }

  closeRenameModal() {
    this.showRenameModal = false;
  }

  saveRenameModal() {
    const message = {
      name: format('{0}{1}{2}', this.documentNameCopy.trim(), '.', this.document.extension),
      index: this.index
    };
    publish(this.context, DEC_RENAME_TEMPLATE_DOCUMENT, message);
  }

  handleNameChange(event) {
    event.preventDefault();
    this.documentNameCopy = event.target.value;
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
        this.openRenameModal();
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