import {
  LightningElement,
  api
} from 'lwc';
import {
  isEmpty,
  format,
  formatFileSize
} from 'c/utils';
import {
  LABEL,
  TEMPLATE_DOCUMENT_ACTIONS,
  TEMPLATE_DOCUMENT_DELETE_ACTION
} from 'c/documentUtils';

// Lightning message service
import {
  createMessageContext,
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
  isDocHavingExtension = true;
  context = createMessageContext();

  label = LABEL;
  templateDocumentActions = TEMPLATE_DOCUMENT_ACTIONS;
  templateDocumentDeleteAction = TEMPLATE_DOCUMENT_DELETE_ACTION;

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
    let docLength = docName.lastIndexOf('.') !== -1 ? docName.lastIndexOf('.') : docName.length;
    this.isDocHavingExtension = docName.lastIndexOf('.') !== -1 ? true : false;
    this.documentNameCopy = docName.substring(0, docLength);
    this.showRenameModal = true;
  }

  closeRenameModal() {
    this.showRenameModal = false;
  }

  saveRenameModal() {
    let docName = this.isDocHavingExtension === true ?
      format('{0}{1}{2}', this.documentNameCopy.trim(), '.', this.document.extension) :
      this.documentNameCopy.trim();
    const message = {
      name: docName,
      index: this.index
    };
    publish(this.context, DEC_RENAME_TEMPLATE_DOCUMENT, message);
    this.closeRenameModal();
  }

  handleNameChange(event) {
    event.preventDefault();
    this.documentNameCopy = event.target.value;
  }

  previewFile() {
    window.open('/' + this.document.sourceId, '_blank');
  }

  handleFileOption(event) {
    let action = event.detail.value;

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