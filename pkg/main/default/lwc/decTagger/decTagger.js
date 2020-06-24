import {LightningElement, api} from 'lwc';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';


// Publisher
import ERROR from '@salesforce/messageChannel/Error__c';

//import Apex Controller method
import getDecTaggerUrl from '@salesforce/apex/EnvelopeConfigurationController.getDecTaggerUrl';

export default class DecTagger extends LightningElement {
  @api recordId;
  isLoading = true;
  context = createMessageContext();

  connectedCallback() {
    this.navigateToDecTagger(this.recordId);
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  navigateToDecTagger(templateId) {
    getDecTaggerUrl({
      decTemplateId: templateId
    })
      .then(result => {
        window.location = result;
      })
      .catch(error => {
        this.isLoading = false;
        this.showError(error);
      });
  }

  showError(errorMessage) {
    publish(this.context, ERROR, { errorMessage });
  }
}