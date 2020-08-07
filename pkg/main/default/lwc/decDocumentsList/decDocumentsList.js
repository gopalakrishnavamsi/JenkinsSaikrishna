import { LightningElement, api } from 'lwc';
import {
    handleDragEnter,
    handleDragOver,
    handleDragLeave,
    handleDrop,
    itemDragStart,
    itemDragEnd
} from 'c/dragUtils';
import { DOCUMENT_TYPE_SOURCE_FILES } from 'c/documentUtils';
import {getRandomKey} from 'c/utils';

export default class DecDocumentsList extends LightningElement {
    @api
    list;

    fromIndex = null;

    // Document-specific property for envelope configuration
    @api
    attachSourceFiles;

    get key() {
        return getRandomKey();
    }

    handleDragEnter(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            handleDragEnter(this, evt);
        }
    }
    
    handleDragOver(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            handleDragOver(this, evt);
        }
    }
    
    handleDragLeave(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            handleDragLeave(this, evt);
        }
    }

    itemDragStart(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            itemDragStart(this, evt.currentTarget.dataset.id);
        }
    }

    itemDragEnd(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            itemDragEnd(this, evt.currentTarget.dataset.id);
        }
    }

    handleDrop(evt) {
        if (evt.currentTarget.dataset.type !== DOCUMENT_TYPE_SOURCE_FILES) {
            handleDrop(this, evt, this.updateDocuments.bind(this));
        }
    }

    /** Document-specific functions for envelope configuration **/

    updateDocuments(documents) {
        this.dispatchEvent(new CustomEvent('updatedocuments', {
            detail: {
                documents
            },
            bubbles: true
        }));
    }
}