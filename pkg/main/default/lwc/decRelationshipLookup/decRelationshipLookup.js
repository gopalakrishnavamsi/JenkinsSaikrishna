import { LightningElement, api, track } from 'lwc';
import getChildRelationships from '@salesforce/apex/EnvelopeConfigurationController.getChildRelationships';
import getLookupFields from '@salesforce/apex/EnvelopeConfigurationController.getLookupFields';
import { Relationship } from 'c/queryUtils';
import loadingLabel from '@salesforce/label/c.Loading';
import { isEmpty } from 'c/utils';

export default class DecRelationshipLookup extends LightningElement {

    @api
    label = '';

    @api
    placeHolder;

    @api
    sourceObject = null;

    @api
    isLookup = false;

    @track
    selectedRelationship = null;

    relationships = [];

    searchResults = null;

    searchTerm;  
    
    errorMessage;

    connectedCallback() {
        if (isEmpty(this.sourceObject)) return;

        if (this.isLookup) {
            getLookupFields({
                sourceObject: this.sourceObject
            })
            .then(this.initRelationships)
            .catch(this.handleInitError)
        } else {
            getChildRelationships({
                sourceObject: this.sourceObject
            })
            .then(this.initRelationships) 
            .catch(this.handleInitError)
        }
    }

    get message() {
        return this.showResultPanel ? null : loadingLabel;
    }

    get showResultPanel() {
        return !isEmpty(this.searchResults);
    }

    get hasSelection() {
        return !isEmpty(this.selectedRelationship);
    }

    get resultClass() {
        return this.searchTerm ? 
        'slds-form-element slds-lookup slds-is-open' :
        'slds-form-element slds-lookup slds-is-close';        
    }

    initRelationships = results => {
        this.relationships = results.map(r => Relationship.fromObject(r))
        this.resetSearch(this.relationships)
    }

    handleInitError = () => {
        //TODO
    }

    resetSearch(results = null) {
        this.searchTerm = null;
        this.searchResults = results;
    }

    handleInput({ detail }) {
        if (detail.value === undefined) return;
        
        this.searchTerm = detail.value.trim();
        if (isEmpty(this.searchTerm)) {
            this.searchResults = this.relationships;
        } else {
            this.searchResults = this.relationships.filter(r => r.label.toLowerCase().indexOf(this.searchTerm.toLowerCase()) > -1);
        }
    }

    handlePillRemove() {
        this.selectedRelationship = null;
        const payload = {
            detail: {}
        };
        this.dispatchEvent(new CustomEvent('selection', payload));
    }

    handleError(error) {
        this.showSpinner = false;
        this.dispatchEvent(new CustomEvent('failure', { detail: error }));
    }

    handleSelect = ({ detail }) => {
        this.selectedRelationship = this.searchResults[detail];
        this.dispatchEvent(new CustomEvent('relationshipupdate', { detail: this.selectedRelationship }));
        this.resetSearch(this.relationships);
    }
}