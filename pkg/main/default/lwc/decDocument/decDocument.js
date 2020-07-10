import { LightningElement, api } from 'lwc';

// utility functions
import {isEmpty} from 'c/utils';
import { DOCUMENT_TYPE_TEMPLATE_DOCUMENT, DOCUMENT_TYPE_SOURCE_FILES } from 'c/documentUtils';

export default class DecDocument extends LightningElement {
    @api
    document;

    @api
    index;

    @api
    attachSourceFiles;

    get documentSequence() {
        return this.index + 1;
    }

    get isTemplateDocument() {
        return isEmpty(this.document) ? false :
          this.document.type === DOCUMENT_TYPE_TEMPLATE_DOCUMENT;
    }

    get isSourceFiles() {
        return isEmpty(this.document) ? false :
          this.document.type === DOCUMENT_TYPE_SOURCE_FILES;
    }
}