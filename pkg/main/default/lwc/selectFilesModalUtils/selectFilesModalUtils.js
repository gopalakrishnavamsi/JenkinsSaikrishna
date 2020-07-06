import addFromSalesforce from '@salesforce/label/c.AddFromSalesforce';
import ownedByMe from '@salesforce/label/c.OwnedByMe';
import sharedWithMe from '@salesforce/label/c.SharedWithMe';
import recent from '@salesforce/label/c.Recent';
import following from '@salesforce/label/c.Following';
import libraries from '@salesforce/label/c.Libraries';
import searchFiles from '@salesforce/label/c.SearchFiles';
import searchTermMinLengthMessage from '@salesforce/label/c.SearchTermMinLengthMessage';
import cancel from '@salesforce/label/c.Cancel';
import add from '@salesforce/label/c.Add';
import back from '@salesforce/label/c.Back';
import emptyFileResultsMessage from '@salesforce/label/c.EmptyFileResultsMessage';
import selectedFilesOfTotalFiles from '@salesforce/label/c.SelectedFilesOfTotalFiles';

const LABEL = {
  addFromSalesforce,
  back,
  searchFiles,
  searchTermMinLengthMessage,
  cancel,
  add,
  ownedByMe,
  sharedWithMe,
  recent,
  following,
  libraries,
  emptyFileResultsMessage,
  selectedFilesOfTotalFiles
};

export {
  LABEL
}