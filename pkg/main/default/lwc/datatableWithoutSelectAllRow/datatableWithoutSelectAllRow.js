import {LightningElement, api} from 'lwc';
import {formatFileSize, genericEvent} from 'c/utils';

export default class DatatableWithoutSelectAllRow extends LightningElement {
  @api rowid;
  @api name;
  @api extension;
  @api filesize;

  get formattedFileSize() {
    return formatFileSize(this.filesize, 0);
  }

  handleSelection(event) {
    let data = {
      rowid: this.rowid,
      selected: event.target.checked
    };
    genericEvent.call(
      this,
      'selectedrow',
      data,
      true,
      true,
      true);
  }

  previewFile() {
    window.open('/' + this.rowid, '_blank');
  }
}