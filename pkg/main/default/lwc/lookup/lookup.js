import {LightningElement, api} from 'lwc';
import getRecords from '@salesforce/apex/LookupController.getRecords';
import {isEmpty} from 'c/utils';
import searchByName from '@salesforce/label/c.SearchByName';
import searching from '@salesforce/label/c.Searching';
import noSearchResults from '@salesforce/label/c.NoSearchResults';

export default class Lookup extends LightningElement {

  @api label;

  resultClass;
  selectedRecord = null;
  resultsData = null;
  message = null;
  showSpinner = false;
  lastSearchValue = null;

  customLabel = {
    searchByName: searchByName
  };

  constructor() {
    super();
    this.switchResult(false);
  }

  handleChange(event) {
    let searchTerm = event.detail;
    if (searchTerm && searchTerm.length >= 2) {
      this.switchResult(true);
      this.message = searching;
      this.showSpinner = true;

      let searchParams = {
        searchTerm: searchTerm,
      };

      getRecords(searchParams)
        .then(response => this.setResult(response, searchTerm))
        .catch(error => this.handleError(error));

    } else {
      this.switchResult(false);
      this.showSpinner = false;
    }
    this.lastSearchValue = searchTerm;
  }

  setResult(response, searchTerm) {
    this.showSpinner = false;
    this.message = null;
    if (response
      && response.isSuccess
      && searchTerm === response.results.searchTerm
      && !isEmpty(response.results.data)
      && response.results.data.length > 0) {
      this.resultsData = response.results.data;
    } else {
      this.resultsData = null;
      this.message = response.errMsg ? response.errMsg : noSearchResults;
    }
  }

  /* Shows and hides the result area */
  switchResult(on) {
    this.resultClass = on
      ? 'slds-form-element slds-lookup slds-is-open'
      : 'slds-form-element slds-lookup slds-is-close';
  }

  handlePillRemove() {
    this.selectedRecord = null;
    let payload = {
      detail: {
        record: {}
      }
    };
    let selectionDispatch = new CustomEvent('selection', payload);
    this.dispatchEvent(selectionDispatch);
    // Restore last results
    this.switchResult(this.lastSearchValue && this.resultsData);
  }

  handleError(error) {
    this.showSpinner = false;
    this.message = error.message;
    let errorDispatch = new CustomEvent('failure', {detail: error});
    this.dispatchEvent(errorDispatch);
  }

  handleRecordSelect(event) {
    let record = event.detail;
    let payload = {
      detail: {
        record: record
      }
    };
    this.selectedRecord = record;
    let selectionDispatch = new CustomEvent('selection', payload);
    this.dispatchEvent(selectionDispatch);
    this.switchResult(false);
  }

  get iconName() {
    return 'standard:' + this.selectedRecord.objType.toLowerCase();
  }

  get showResultPanel() {
    return this.resultsData && this.resultsData.length > 0;
  }

}