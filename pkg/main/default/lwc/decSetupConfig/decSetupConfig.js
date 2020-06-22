import {LightningElement, api, wire} from 'lwc';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
// Publisher
import ERROR from '@salesforce/messageChannel/Error__c';
import DEC_UPDATE_PAGE_LAYOUTS from '@salesforce/messageChannel/DecUpdatePageLayouts__c';
// Subscriber
import DEC_UPDATE_SOURCE_FILES from '@salesforce/messageChannel/DecUpdateSourceFiles__c';
import DEC_RENAME_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecRenameTemplateDocument__c';
import DEC_DELETE_TEMPLATE_DOCUMENT from '@salesforce/messageChannel/DecDeleteTemplateDocument__c';
import DEC_RENAME_ENVELOPE_TEMPLATE from '@salesforce/messageChannel/DecRenameEnvelopeTemplate__c';
import DEC_UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/DecUpdateNotifications__c';

// utility functions
import {
  isEmpty,
  subscribeToMessageChannel,
  showError
} from 'c/utils';
import {DOCUMENT_TYPE_SOURCE_FILES} from 'c/documentUtils';
import {LABEL} from 'c/setupUtils';

//apex methods
import updateEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.updateEnvelopeConfiguration';
import getEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.getEnvelopeConfiguration';

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
};

export default class DecSetupConfig extends LightningElement {
  @api recordId;
  currentStep = MIN_STEP;
  envelopeConfigurationData;
  isLoading = false;
  context = createMessageContext();
  contentDocumentIdsToDelete = [];

  // Subscriptions
  sourceFilesSubscription = null;
  renameEnvelopeTemplateSubscription = null;
  renameTemplateDocSubscription = null;
  deleteTemplateDocSubscription = null;
  updateNotificationsSubscription = null;

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
    this.sourceFilesSubscription = subscribeToMessageChannel(
      this.context,
      this.sourceFilesSubscription,
      DEC_UPDATE_SOURCE_FILES,
      this.handleToggleSourceFiles.bind(this)
    );

    this.renameTemplateDocSubscription = subscribeToMessageChannel(
      this.context,
      this.renameTemplateDocSubscription,
      DEC_RENAME_TEMPLATE_DOCUMENT,
      this.handleRenameTemplateDocument.bind(this)
    );

    this.deleteTemplateDocSubscription = subscribeToMessageChannel(
      this.context,
      this.deleteTemplateDocSubscription,
      DEC_DELETE_TEMPLATE_DOCUMENT,
      this.handleDeleteTemplateDocument.bind(this)
    );

    this.renameEnvelopeTemplateSubscription = subscribeToMessageChannel(
      this.context,
      this.renameEnvelopeTemplateSubscription,
      DEC_RENAME_ENVELOPE_TEMPLATE,
      this.handleRenameEnvelopeTemplate.bind(this)
    );

    this.updateNotificationsSubscription = subscribeToMessageChannel(
      this.context,
      this.updateNotificationsSubscription,
      DEC_UPDATE_NOTIFICATIONS,
      this.handleUpdateNotifications.bind(this)
    );
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @wire(getEnvelopeConfiguration, {
    recordId: '$recordId'
  })
  getEnvelopeConfigurationData({error, data}) {
    if (error) {
      showError(this.context, error, ERROR);
      this.setLoading(false);
    } else if (data) {
      this.attachSourceFiles = !isEmpty(data.documents.find(d => d.type === DOCUMENT_TYPE_SOURCE_FILES));
      this.envelopeConfigurationData = data;
    }
  }

  get documents() {
    return isEmpty(this.envelopeConfigurationData) ? [] : this.envelopeConfigurationData.documents;
  }

  get recipients() {
    return isEmpty(this.envelopeConfigurationData) ? [] : this.envelopeConfigurationData.recipients;
  }

  get emailMessage() {
    return isEmpty(this.envelopeConfigurationData) ? [] : this.envelopeConfigurationData.emailMessage;
  }

  get emailSubject() {
    return isEmpty(this.envelopeConfigurationData) ? [] : this.envelopeConfigurationData.emailSubject;
  }

  get notifications() {
    return isEmpty(this.envelopeConfigurationData) || isEmpty(this.envelopeConfigurationData.notifications) ? null : this.envelopeConfigurationData.notifications;
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

  handleToggleSourceFiles(message) {
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
    if (isValidStep) {
      operation === OPERATION.BACK ? --stepNumber : ++stepNumber;
      this.updateEnvelopeConfiguration(stepNumber.toString());
    }
  }

  handleSaveAndClose() {
    if (this.currentStep === PROGRESS_STEP.CUSTOM_BUTTON) {
      const msg = {
        recordId: this.recordId
      };
      publish(this.context, DEC_UPDATE_PAGE_LAYOUTS, msg);
    } else {
      this.updateEnvelopeConfiguration();
    }
  }

  handleRenameEnvelopeTemplate(message) {
    this.updateEnvelopeConfiguration(null, {
      ...this.envelopeConfigurationData,
      name: message.name
    });
  }

  handleUpdateNotifications(message) {
    this.updateLocalConfiguration({
      notifications: message.notifications
    });
  }

  updateLocalConfiguration(fieldsToUpdate) {
    this.envelopeConfigurationData = {
      ...this.envelopeConfigurationData,
      ...fieldsToUpdate
    };
  }

  updateLocalData(event) {
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, documents: event.detail.data};
  }

  handleUpdateDocument(event) {
    let docs = this.envelopeConfigurationData.documents;
    docs = [...docs, {...event.detail.data}];
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, documents: docs};
  }

  handleUpdateRecipient(event) {
    let recipients = this.envelopeConfigurationData.recipients;
    recipients = [...recipients, {...event.detail.data}];
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, recipients: recipients};
  }

  handleOnClickProgressStep(event) {
    this.updateEnvelopeConfiguration(event.detail.data);
  }

  setLoading(isTrue) {
    this.isLoading = isTrue ? true : false;
  }

  handleRenameTemplateDocument(message) {
    const documentName = message.name;
    const documentIndex = message.index;
    const documents = this.envelopeConfigurationData.documents.map((d, i) => {
      if (i === documentIndex) {
        return {...d, name: documentName};
      }
      return d;
    });
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, documents};
  }

  handleDeleteTemplateDocument(message) {
    const documents = this.envelopeConfigurationData.documents.filter((d, i) => i !== message.index);
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, documents};
    this.contentDocumentIdsToDelete.push(message.contentDocumentId);
  }

  handleEmailChange({detail}) {
    const {emailMessage = null, emailSubject = null} = detail.data;
    this.updateLocalConfiguration({
      emailMessage: emailMessage,
      emailSubject: emailSubject
    });
  }

  updateEnvelopeConfiguration(step, configurationData = this.envelopeConfigurationData) {
    this.setLoading(true);
    const updatedConfiguration = this.getFilteredConfigurationData(configurationData);
    updateEnvelopeConfiguration({
      envelopeConfigurationJSON: updatedConfiguration,
      attachSourceFiles: this.attachSourceFiles,
      contentDocumentIdsToDelete: this.contentDocumentIdsToDelete
    })
      .then(result => {
        this.envelopeConfigurationData = result;
        this.currentStep = isEmpty(step) ? this.currentStep : step;
        this.setLoading(false);
      })
      .catch(error => {
        showError(this.context, error, ERROR);
        this.setLoading(false);
      });
  }

  // Process configuration data before updating it in server
  getFilteredConfigurationData(configurationData) {
    if (isEmpty(configurationData)) {
      return null;
    }
    const processedFields = {};

    let recipientsSelector = this.template.querySelector('c-dec-recipients');
    if (!isEmpty(recipientsSelector)) {
      let recipients = recipientsSelector.fetchRecipients();
      if (recipients) processedFields.recipients = recipients.map(r => ({...r, id: null}));
    } else {
      processedFields.recipients = configurationData.recipients.map(r => ({...r, id: null}));
    }
    processedFields.documents = configurationData.documents.map(doc => ({...doc, id: null}));
    return JSON.stringify({
      ...configurationData,
      ...processedFields
    });
  }
}