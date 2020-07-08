import { LightningElement, api} from 'lwc';

// utility functions
import {isEmpty} from 'c/utils';
import {
    LABEL,
    SOURCE_FILES_TYPES,
    SOURCE_FILES_MENU_OPTIONS,
    FILE_NAME_FILTER_PREFIX,
    FILE_NAME_FILTER_SUFFIX,
    LATEST_SOURCE_FILES_ORDER_BY,
    FILE_NAME_CONTAINS_ORDER_BY
} from 'c/documentUtils';

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

    get sourceFilesMenuOptions() {
        return SOURCE_FILES_MENU_OPTIONS;
    }

    connectedCallback() {
        this.loadSourceFilesType();
    }

    loadSourceFilesType() {
        if (!isEmpty(this.document.filter)) {
            if (!isEmpty(this.document.filter.orderBy) && this.document.filter.maximumRecords === 1) {
                this.sourceFilesType = SOURCE_FILES_TYPES.LATEST;
            } else if (!isEmpty(this.document.filter.filterBy)) {
                let filterBy = this.document.filter.filterBy;
                this.containsValue = filterBy.substring(filterBy.indexOf(FILE_NAME_FILTER_PREFIX) + FILE_NAME_FILTER_PREFIX.length, filterBy.lastIndexOf(FILE_NAME_FILTER_SUFFIX));
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
                orderBy: LATEST_SOURCE_FILES_ORDER_BY,
                maximumRecords: 1
            }
        });
    }

    setContainsSourceFiles() {
        this.updateDocument({
            ... this.document,
            filter: {
                filterBy: this.containsValue,
                orderBy: FILE_NAME_CONTAINS_ORDER_BY,
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