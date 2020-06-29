import LightningDatatable from 'lightning/datatable';
import individualSelectRow from './individualSelectRow.html';

export default class DatatableWithoutSelectAll extends LightningDatatable {
  static customTypes = {
    selectRow: {
      template: individualSelectRow,
      standardCellLayout: true,
      typeAttributes: ['rowid', 'extension', 'filesize']
    }
  };
}