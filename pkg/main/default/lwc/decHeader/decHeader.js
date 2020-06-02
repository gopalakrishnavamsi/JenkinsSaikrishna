import { LightningElement, api } from 'lwc';

// utility functions
import { isEmpty } from 'c/utils';
import { LABEL } from 'c/setupUtils';

// Lightning message service
import {createMessageContext,
    releaseMessageContext,
    publish
  } from 'lightning/messageService';
  // Publisher
  import DEC_RENAME_ENVELOPE_TEMPLATE from '@salesforce/messageChannel/DecRenameEnvelopeTemplate__c';

export default class DecHeader extends LightningElement {
    showRenameModal = false;
    nameCopy;
    @api
    icon;

    @api
    headerName;

    @api
    subHeaderName;

    @api
    modalTitle;

    @api
    isFinalStep;

    @api
    isFirstStep;

    label = LABEL;

    context = createMessageContext();

    disconnectedCallback() {
      releaseMessageContext(this.context);
    }

    get saveLabel() {
        return this.isFinalStep ? this.label.saveAndFinish : this.label.saveAndClose;
    }
    
    get saveLabelClass() {
        return this.isFinalStep ? 'brand' : 'neutral';
    }

    get disableModalSave() {
        return isEmpty(this.nameCopy) || this.nameCopy.trim().length === 0;
    }

    openRenameModal() {
        this.showRenameModal = true;
        this.nameCopy = this.subHeaderName;
    }
    
    closeRenameModal() {
        this.showRenameModal = false;
    }
    
    saveRenameModal() {
        const message = {
            name: this.nameCopy.trim()
        };
        publish(this.context, DEC_RENAME_ENVELOPE_TEMPLATE, message);
        this.closeRenameModal();
    }

    
    handleNameChange(event) {
        event.preventDefault();
        this.nameCopy = event.target.value;
    }

    handleSaveAndClose() {
        this.dispatchEvent(new CustomEvent('saveandclose'));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next'));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
}