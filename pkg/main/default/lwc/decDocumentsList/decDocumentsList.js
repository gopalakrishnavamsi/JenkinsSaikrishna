import { LightningElement, api } from 'lwc';
import {
    handleDragEnter,
    handleDragOver,
    handleDragLeave,
    addDragOverStyle,
    removeDragOverStyle,
    handleDrop,
    itemDragStart,
    itemDragEnd
} from 'c/dragUtils';

export default class DecDocumentsList extends LightningElement {
    @api
    list;

    fromIndex = null;

    // Document-specific property for envelope configuration
    @api
    attachSourceFiles;

    handleDragEnter(evt) {
        handleDragEnter(this, evt);
    }
    
    handleDragOver(evt) {
        handleDragOver(this, evt);
    }
    
    handleDragLeave(evt) {
        handleDragLeave(this, evt);
    }
    
    addDragOverStyle(index) {
        addDragOverStyle(this, index);
    }
    
    removeDragOverStyle(index) {
        removeDragOverStyle(this, index);
    }

    itemDragStart(evt) {
        itemDragStart(this, evt.currentTarget.dataset.id);
    }

    itemDragEnd(evt) {
        itemDragEnd(this, evt.currentTarget.dataset.id);
    }

    handleDrop(evt) {
        handleDrop(this, evt, this.updateDocuments.bind(this));
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