import {LightningElement, api} from 'lwc';
import {genericEvent} from 'c/utils';

export default class DatatableContentWorkspaceColumn extends LightningElement {
  @api name;
  @api rowid;

  handleClickOnWorkspace() {
    let data = this.rowid;
    genericEvent.call(
      this,
      'displaycontentdocumentsinworkspace',
      data,
      true,
      true,
      true);
  }
}