import LightningDatatable from 'lightning/datatable';
import contentWorkspaceRow from './contentWorkspaceRow.html';

export default class DatatableContentWorkspace extends LightningDatatable {
  static customTypes = {
    contentWorkspace: {
      template: contentWorkspaceRow,
      standardCellLayout: true,
      typeAttributes: ['rowid']
    }
  };
}