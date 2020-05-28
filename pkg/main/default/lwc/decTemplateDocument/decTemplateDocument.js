import {LightningElement, api} from 'lwc';
import {formatFileSize} from 'c/utils';

export default class DecTemplateDocument extends LightningElement {
  @api document;

  get fileSize() {
    return formatFileSize(this.document.size, 0);
  }

  previewFile() {
    window.open('/' + this.document.sourceId, '_blank');
  }
}