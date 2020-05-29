import {LightningElement, api, wire} from 'lwc';

// Lightning message service
import {createMessageContext,
        releaseMessageContext,
        publish,
        APPLICATION_SCOPE,
        subscribe} from 'lightning/messageService';
// Publisher
import DEC_ERROR from '@salesforce/messageChannel/DecError__c';
// Subscriber
import DEC_UPDATE_SOURCE_FILES from '@salesforce/messageChannel/DecUpdateSourceFiles__c';
import DEC_DELETE_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecDeleteTemplateDocument__c';


// utility functions
import { isEmpty } from 'c/utils';
import { DOCUMENT_TYPE_SOURCE_FILES } from 'c/documentUtils';
import { LABEL } from 'c/setupUtils';

//apex methods
import updateEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.updateEnvelopeConfiguration';
import getEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.getEnvelopeConfiguration';
import deleteContentDocument from '@salesforce/apex/EnvelopeConfigurationController.deleteContentDocument';

const MAX_STEP = '6';
const MIN_STEP = '1';

const PROGRESS_STEP = {
  DOCUMENTS: '1',
  RECIPIENTS: '2',
  MERGE_FIELDS: '3',
  TAGGER: '4',
  OPTIONS: '5',
  CUSTOM_BUTTON: '6'
};

const OPERATION = {
  BACK: 'back',
  NEXT: 'next'
}

export default class DecSetupConfig extends LightningElement {
  @api recordId;
  currentStep = MIN_STEP;
  envelopeConfigurationData;
  isLoading = false;
  context = createMessageContext();
  sourceFilesSubscription = null;
  templateDocumentSubscription = null;

  @api
  attachSourceFiles = false;
  label = LABEL;

  steps = [
    {'label': this.label.documents, 'value': PROGRESS_STEP.DOCUMENTS},
    {'label': this.label.recipients, 'value': PROGRESS_STEP.RECIPIENTS},
    {'label': this.label.mergeFields, 'value': PROGRESS_STEP.MERGE_FIELDS},
    {'label': this.label.tagger, 'value': PROGRESS_STEP.TAGGER},
    {'label': this.label.options, 'value': PROGRESS_STEP.OPTIONS},
    {'label': this.label.customButton, 'value': PROGRESS_STEP.CUSTOM_BUTTON}];

  connectedCallback() {
    this.subscribeToSourceFilesMessageChannel();
    this.subscribeToTemplateDocumentMessageChannel();
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @wire(getEnvelopeConfiguration, {
    recordId: '$recordId'
  })
  getEnvelopeConfigurationData({error, data}) {
    if (error) {
      this.showError(error);
    } else if (data) {
      this.attachSourceFiles = !isEmpty(data.documents.find(d => d.type === DOCUMENT_TYPE_SOURCE_FILES));
      this.envelopeConfigurationData = data;
    }
  }

  get documents() {
    return isEmpty(this.envelopeConfigurationData) ? [] : this.envelopeConfigurationData.documents;
  }

  // Passed to decHeader
  get configurationName() {
    return this.envelopeConfigurationData ? this.envelopeConfigurationData.name : '';
  }

  get documentsStep() {
    return this.currentStep === PROGRESS_STEP.DOCUMENTS;
  }

  get recipientsStep() {
    return this.currentStep === PROGRESS_STEP.RECIPIENTS;
  }

  get mergeFieldsStep() {
    return this.currentStep === PROGRESS_STEP.MERGE_FIELDS;
  }

  get taggerStep() {
    return this.currentStep === PROGRESS_STEP.TAGGER;
  }

  get optionsStep() {
    return this.currentStep === PROGRESS_STEP.OPTIONS;
  }

  get customButtonStep() {
    return this.currentStep === PROGRESS_STEP.CUSTOM_BUTTON;
  }

  get disableSave() {
    return this.envelopeNameCopy === undefined || this.envelopeNameCopy.trim().length === 0;
  }

  get sourceObject() {
    return this.envelopeConfigurationData ? this.envelopeConfigurationData.sourceObject : null;
  }  

  subscribeToSourceFilesMessageChannel() {
    if (this.sourceFilesSubscription) {
      return;
    }
    this.sourceFilesSubscription = subscribe(this.context, DEC_UPDATE_SOURCE_FILES, (message) => {
      this.handleSourceFilesSubscription(message);
    }, {
      scope: APPLICATION_SCOPE
    });
  }

  subscribeToTemplateDocumentMessageChannel() {
    if (this.templateDocumentSubscription) {
      return;
    }
    this.templateDocumentSubscription = subscribe(this.context, DEC_DELETE_TEMPLATE_DOCUMENT, (message) => {
      this.handleDeleteTemplateDocument(message);
    }, {
      scope: APPLICATION_SCOPE
    });
  }

  handleSourceFilesSubscription(message){
    this.attachSourceFiles = message.isSourceFilesSelected;
  }

  handleBack() {
    this.handleOperation(OPERATION.BACK);
  }

  handleNext() {
    this.handleOperation(OPERATION.NEXT);
  }

  handleOperation(operation) {
    let stepNumber = parseInt(this.currentStep, 10);
    const isValidStep = operation === OPERATION.BACK ? stepNumber > MIN_STEP : stepNumber < MAX_STEP;
    if(isValidStep) {
      operation === OPERATION.BACK ? --stepNumber : ++stepNumber;
      this.updateEnvelopeConfiguration(stepNumber.toString());
    }
  }

  handleSaveAndClose() {
    this.updateEnvelopeConfiguration();
  }

  onRenameSave(event) {
    this.updateLocalData(event);
    this.updateEnvelopeConfiguration();
  }

  updateLocalData(event) {
    this.envelopeConfigurationData = {...this.envelopeConfigurationData,documents: event.detail.data};
  }

  handleUpdateDocument(event) {
    let docs = this.envelopeConfigurationData.documents;
    docs = [...docs, {...event.detail.data}];
    this.envelopeConfigurationData = {...this.envelopeConfigurationData,documents:docs};
    this.updateEnvelopeConfiguration(this.currentStep);
  }

  handleOnClickProgressStep(event) {
    this.updateEnvelopeConfiguration(event.detail.data);
  }

  setLoading(isTrue) {
    this.isLoading = isTrue ? true : false;
  }

  handleDeleteTemplateDocument(message) {
    this.setLoading(true);
    deleteContentDocument({
      contentDocumentId: message.contentDocumentId
    })
      .then(() => {
        const documents = this.envelopeConfigurationData.documents.filter((d, i) => i !== message.index);
        this.envelopeConfigurationData = {
          ... this.envelopeConfigurationData,
          documents
        };
        this.updateEnvelopeConfiguration();
      })
      .catch(this.showError);
  }

  updateEnvelopeConfiguration(step) {
    this.setLoading(true);
    let configurationData = this.getFilteredConfigurationData();
    updateEnvelopeConfiguration({
      envelopeConfigurationJSON: configurationData,
      attachSourceFiles: this.attachSourceFiles
    })
      .then(result => {
        this.envelopeConfigurationData = result;
        this.currentStep = isEmpty(step) ? this.currentStep : step;
        this.setLoading(false);
      })
      .catch(this.showError);
  }

  // Process configuration data before updating it in server
  getFilteredConfigurationData() {
    if (isEmpty(this.envelopeConfigurationData)) {
      return null;
    }

    const processedFields = {};
    
    processedFields.documents = this.envelopeConfigurationData.documents.map(doc => ({ ... doc, id: null }));

    return JSON.stringify({
      ...this.envelopeConfigurationData,
      ...processedFields
    });
  }

  showError(error) {
    if (!isEmpty(error.body)) {
      const msg = {
        errorMessage: error.body.message
      }
      publish(this.context, DEC_ERROR, msg);
    }
    
    this.setLoading(false);
  }
}