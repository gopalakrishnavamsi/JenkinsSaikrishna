import {LightningElement, api} from 'lwc';
import getChildRelationships from '@salesforce/apex/EnvelopeConfigurationController.getChildRelationships';
import getLookupFields from '@salesforce/apex/EnvelopeConfigurationController.getLookupFields';
import {Relationship} from 'c/queryUtils';
import loadingLabel from '@salesforce/label/c.Loading';
import {isEmpty,proxify,getRandomKey} from 'c/utils';
import {Labels} from 'c/recipientUtils';

export default class DecRelationshipLookup extends LightningElement {

  Labels = Labels;

  @api
  label = '';

  @api
  placeHolder;

  @api
  sourceObject = null;

  @api
  isLookup = false;

  selectedRelationship = null;

  relationships = [];

  searchResults = null;

  searchTerm;

  errorMessage;

  @api
  get relationship() {
    return this.selectedRelationship;
  }

  set relationship(val) {
    this.selectedRelationship = proxify(val);
  }

  connectedCallback() {
    if (isEmpty(this.sourceObject)) return;

    if (this.isLookup) {
      getLookupFields({
        sourceObject: this.sourceObject
      })
        .then(this.initRelationships)
        .catch(this.handleInitError);
    } else {
      getChildRelationships({
        sourceObject: this.sourceObject
      })
        .then(this.initRelationships)
        .catch(this.handleInitError);
    }
  }

  get message() {
    return this.showResultPanel ? null : loadingLabel;
  }

  get showResultPanel() {
    return !isEmpty(this.searchResults);
  }

  get hasSelection() {
    return !isEmpty(this.relationship) && !this.relationship.isEmpty;
  }

  get resultClass() {
    return this.searchTerm ?
      'slds-form-element slds-lookup slds-is-open' :
      'slds-form-element slds-lookup slds-is-close';
  }

  get key() {
    return getRandomKey();
  }

  initRelationships = results => {
    this.relationships = results.map(r => Relationship.fromObject(r));
    this.resetSearch(this.relationships);
  };

  handleInitError = () => {
    //TODO
  };

  resetSearch(results = null) {
    this.searchTerm = null;
    this.searchResults = results;
  }

  handleInput({detail}) {
    if (detail.value === undefined) return;

    this.searchTerm = detail.value.trim();
    if (isEmpty(this.searchTerm)) {
      this.searchResults = this.relationships;
    } else {
      this.searchResults = this.relationships.filter(r => r.label.toLowerCase().indexOf(this.searchTerm.toLowerCase()) > -1);
    }
  }

  handlePillRemove = () => {
    this.relationship = null;
    this.dispatchEvent(new CustomEvent('relationshipupdate', {detail: null}));
  }

  handleError(error) {
    this.showSpinner = false;
    this.dispatchEvent(new CustomEvent('failure', {detail: error}));
  }

  handleSelect = ({detail}) => {
    this.relationship = this.searchResults[detail];
    this.dispatchEvent(new CustomEvent('relationshipupdate', {detail: this.relationship}));
    this.resetSearch(this.relationships);
  };
}