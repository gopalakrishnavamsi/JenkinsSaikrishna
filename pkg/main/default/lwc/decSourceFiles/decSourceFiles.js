import { LightningElement, api} from 'lwc';

// utility functions
import {isEmpty} from 'c/utils';
import {LABEL, SOURCE_FILES_TYPES} from 'c/documentUtils';

// Lightning message service - Publisher
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import DEC_UPDATE_SOURCE_FILES from '@salesforce/messageChannel/DecUpdateSourceFiles__c';
import DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP from '@salesforce/messageChannel/DecUpdateDocumentOnDragAndDrop__c';

export default class DecSourceFiles extends LightningElement {
    @api document;
    @api index;
    @api attachSourceFiles;
    label = LABEL;
    sourceFilesType;
    containsValue = '';
    context = createMessageContext();

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }

    get isLatestSelected() {
        return this.sourceFilesType === SOURCE_FILES_TYPES.LATEST;
    }

    get isContainsSelected() {
        return this.sourceFilesType === SOURCE_FILES_TYPES.CONTAINS;
    }

    get isAllSelected() {
        return this.sourceFilesType === SOURCE_FILES_TYPES.ALL;
    }

    get sourceFilesTypes() {
        return SOURCE_FILES_TYPES;
    }

    connectedCallback() {
        this.loadSourceFilesType();
    }

    loadSourceFilesType() {
        if (!isEmpty(this.document.filter)) {
            if (!isEmpty(this.document.filter.orderBy) && this.document.filter.maximumRecords === 1) {
                this.sourceFilesType = SOURCE_FILES_TYPES.LATEST;
            } else if (!isEmpty(this.document.filter.filterBy)) {
                this.containsValue = this.document.filter.filterBy;
                this.sourceFilesType = SOURCE_FILES_TYPES.CONTAINS;
            } else {
                this.sourceFilesType = SOURCE_FILES_TYPES.ALL;
            }
        }
    }

    updateSourceFilesDocument() {
        if (this.sourceFilesType === SOURCE_FILES_TYPES.LATEST) {
            this.setLatestSourceFiles();
        } else if (this.sourceFilesType === SOURCE_FILES_TYPES.CONTAINS) {
            this.setContainsSourceFiles();
        } else if (this.sourceFilesType === SOURCE_FILES_TYPES.ALL) {
            this.setAllSourceFiles();
        }
    }

    handleToggleSourceFiles(event) {
        const message = {
            isSourceFilesSelected : event.target.checked
        }
        publish(this.context, DEC_UPDATE_SOURCE_FILES, message);
    }

    handleSourceFilesChange(event) {
        this.sourceFilesType = event.target.value;
        this.updateSourceFilesDocument();
    }

    setLatestSourceFiles() {
        this.updateDocument({
            ... this.document,
            filter: {
                filterBy: '',
                orderBy: 'CreatedDate DESC',
                maximumRecords: 1
            }
        });
    }

    setContainsSourceFiles() {
        this.updateDocument({
            ... this.document,
            filter: {
                filterBy: this.containsValue,
                orderBy: '',
                maximumRecords: null
            }
        });
    }

    setAllSourceFiles() {
        this.updateDocument({
            ... this.document,
            filter: {
                filterBy: '',
                orderBy: '',
                maximumRecords: null
            }
        });
    }

    updateDocument(document) {
        const message = {
            document : document,
            index : this.index
        };
        publish(this.context, DEC_UPDATE_DOCUMENT_ON_DRAG_AND_DROP, message);
    }

    handleContainsValue(event) {
        this.containsValue = event.target.value;
        this.setContainsSourceFiles();
    }
}