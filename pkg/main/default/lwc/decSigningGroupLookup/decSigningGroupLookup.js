import {LightningElement, api} from 'lwc';
import getSigningGroups from '@salesforce/apex/EnvelopeConfigurationController.getSigningGroups';
import loadingLabel from '@salesforce/label/c.Loading';
import {Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';

export default class DecSigningGroupLookup extends LightningElement {
  @api
  label;

  @api
  placeHolder;

  @api
  isLookup = false;

  selectedSigningGroup = null;

  signingGroups = [];

  searchResults = null;

  searchTerm;

  isLoading = true;

  @api
  value;

  connectedCallback() {
    getSigningGroups()
      .then(res => {
        this.signingGroups = this.getSigningGroupOptions(res);
        this.resetSearch(this.signingGroups);
        this.isLoading = false;
      })
      .catch(() => {
        this.isLoading = false;
        //TODO.. Handle Error
      });
  }

  getSigningGroupOptions(signingGroups) {
    return signingGroups.map(({id = null, name = Labels.untitledLabel}) => {
      return {
        id,
        name
      };
    });
  }

  get selected() {
    return this.selectedSigningGroup;
  }

  get message() {
    return this.isLoading ? loadingLabel : null;
  }

  get showResultPanel() {
    return !isEmpty(this.searchResults);
  }

  get hasSelection() {
    return !isEmpty(this.selectedSigningGroup);
  }

  get resultClass() {
    return this.searchTerm ?
      'slds-form-element slds-lookup slds-is-open' :
      'slds-form-element slds-lookup slds-is-close';
  }

  resetSearch(results = null) {
    this.searchTerm = null;
    this.searchResults = results;
  }

  handleInput({detail}) {
    if (detail.value === undefined) return;
    this.searchTerm = detail.value.trim();
    if (isEmpty(this.searchTerm)) {
      this.searchResults = this.signingGroups;
    } else {
      this.searchResults = this.signingGroups.filter(s => s.name.toLowerCase().indexOf(this.searchTerm) > -1);
    }
  }

  handlePillRemove() {
    this.selectedSigningGroup = null;
    this.dispatchEvent(new CustomEvent('selection', {detail: {}}));
  }

  handleError(error) {
    this.showSpinner = false;
    this.dispatchEvent(new CustomEvent('failure', {detail: error}));
  }

  handleSelect = ({detail}) => {
    this.selectedSigningGroup = this.searchResults[detail];
    this.dispatchEvent(new CustomEvent('selection', {detail: this.selectedSigningGroup}));
    this.resetSearch(this.signingGroups);
  };
}