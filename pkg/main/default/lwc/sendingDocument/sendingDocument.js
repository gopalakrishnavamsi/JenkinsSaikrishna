import {LightningElement, api} from 'lwc';
import {isEmpty, formatFileSize, format} from 'c/utils';
import {
  LABEL,
  SENDING_TEMPLATE_DOCUMENT_ACTIONS,
  SENDING_TEMPLATE_DOCUMENT_REMOVE_ACTION,
  DOCUMENT_TYPE_CONTENT_VERSION
} from 'c/documentUtils';
// Publisher
import SENDING_RENAME_DOCUMENT from '@salesforce/messageChannel/SendingRenameDocument__c';
import SENDING_REMOVE_DOCUMENT from '@salesforce/messageChannel/SendingRemoveDocument__c';
import SENDING_TOGGLE_DOCUMENT_SELECTION from '@salesforce/messageChannel/SendingToggleDocumentSelection__c';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';

const ATTACHMENT = 'attachment';

export default class SendingDocument extends LightningElement {
  @api document;
  @api index;
  @api forbidEnvelopeChanges;
  showRenameModal = false;
  documentNameCopy;

  context = createMessageContext();

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  label = LABEL;
  templateDocumentActions = SENDING_TEMPLATE_DOCUMENT_ACTIONS;
  templateDocumentRemoveAction = SENDING_TEMPLATE_DOCUMENT_REMOVE_ACTION;

  get isDraggable() {
    return !isEmpty(this.forbidEnvelopeChanges) && !this.forbidEnvelopeChanges;
  }

  get documentExtension() {
    return isEmpty(this.document.extension) ? ATTACHMENT : this.document.extension;
  }

  get hideDragAndDropIcon() {
    return !isEmpty(this.forbidEnvelopeChanges) && this.forbidEnvelopeChanges ? 'slds-hidden' : '';
  }

  get canPreview() {
    return this.document.type === DOCUMENT_TYPE_CONTENT_VERSION && !isEmpty(this.document.sourceId);
  }

  get disableModalSave() {
    return isEmpty(this.documentNameCopy) || this.documentNameCopy.trim().length === 0;
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

  handleFileOption(event) {
    let action = event.detail.value;

    switch (action) {
      case 'preview':
        this.previewFile();
        break;
      case 'rename':
        this.openRenameModal();
        break;
      case 'remove':
        this.removeDocument();
        break;
      default:
        break;
    }
  }

  openRenameModal() {
    const docName = this.document.name;
    this.documentNameCopy = docName.substring(0, docName.lastIndexOf('.'));
    this.showRenameModal = true;
  }

  removeDocument() {
    const message = {
      contentDocumentId: this.document.sourceId,
      index: this.index
    };
    publish(this.context, SENDING_REMOVE_DOCUMENT, message);
  }

  closeRenameModal() {
    this.showRenameModal = false;
  }

  handleNameChange(event) {
    event.preventDefault();
    this.documentNameCopy = event.target.value;
  }

  saveRenameModal() {
    const message = {
      name: format('{0}{1}{2}', this.documentNameCopy.trim(), '.', this.document.extension),
      index: this.index
    };
    publish(this.context, SENDING_RENAME_DOCUMENT, message);
    this.closeRenameModal();
  }
}