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
import UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/UpdateNotifications__c';

// utility functions
import {
  isEmpty,
  subscribeToMessageChannel,
  showError,
  format
} from 'c/utils';
import {getDefaultOptions} from 'c/optionsUtils';
import {
  DOCUMENT_TYPE_SOURCE_FILES,
  FILE_NAME_FILTER_PREFIX,
  FILE_NAME_FILTER_SUFFIX,
  DOCUMENT_TYPE_TEMPLATE_DOCUMENT
} from 'c/documentUtils';
import {
  LABEL,
  PROGRESS_STEP,
  OPERATION,
  MAX_STEP,
  MIN_STEP,
  STEPS
} from 'c/setupUtils';

//apex methods
import updateEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.updateEnvelopeConfiguration';
import getEnvelopeConfiguration from '@salesforce/apex/EnvelopeConfigurationController.getEnvelopeConfiguration';

export default class DecSetupConfig extends LightningElement {
  @api recordId;
  @api currentStep;

  isTaggerDisabled = false;
  isDirty = false;
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
  isEmptyRecipients = false;

  connectedCallback() {
    this.sourceFilesSubscription = subscribeToMessageChannel(
      this.context,
      this.sourceFilesSubscription,
      DEC_UPDATE_SOURCE_FILES,
      this.handleUpdateSourceFiles.bind(this)
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
      UPDATE_NOTIFICATIONS,
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
      this.envelopeConfigurationData = {
        ...data,
        documents: this.attachSourceFiles ? this.processTextSearchSourceFiles(data.documents, true) : data.documents,
        options: isEmpty(data.options.documentWriteBack) ? getDefaultOptions() : data.options,
        emailMessage: isEmpty(data.emailMessage) ? this.label.defaultEmailMessage : data.emailMessage,
        emailSubject: isEmpty(data.emailSubject) ? this.label.defaultEmailSubject : data.emailSubject
      };
      this.updateProgressBar();
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

  get options() {
    return isEmpty(this.envelopeConfigurationData) || isEmpty(this.envelopeConfigurationData.options) ? null : this.envelopeConfigurationData.options;
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

  get showEmailMessage() {
    return this.currentStep === PROGRESS_STEP.RECIPIENTS && !this.isEmptyRecipients;
  }

  handleUpdateSourceFiles(message) {
    this.isDirty = true;

    if (!isEmpty(message.attachSourceFiles) && this.attachSourceFiles !== message.attachSourceFiles) {
      this.attachSourceFiles = message.attachSourceFiles;
      return;
    }

    let documents = this.envelopeConfigurationData.documents.slice();
    documents[message.index] = message.document;

    this.updateLocalConfiguration({
      documents
    });
  }

  handleBack() {
    this.handleOperation(OPERATION.BACK);
  }

  handleNext() {
    this.updateProgressBar();
    this.handleOperation(OPERATION.NEXT);
  }

  handleOperation(operation) {
    let stepNumber = parseInt(this.currentStep, 10);
    const isValidStep = operation === OPERATION.BACK ? stepNumber > MIN_STEP : stepNumber < MAX_STEP;
    if (isValidStep) {
      operation === OPERATION.BACK ? --stepNumber : ++stepNumber;
      if (stepNumber === parseInt(PROGRESS_STEP.TAGGER) && this.isTaggerDisabled === true) {
        stepNumber = operation === OPERATION.BACK ? --stepNumber : ++stepNumber;
      }
      this.updateEnvelopeConfiguration(stepNumber.toString());
    }
  }

  handleSaveAndClose() {
    if (this.currentStep === PROGRESS_STEP.CUSTOM_BUTTON) {
      this.isDirty = true;
      const msg = {
        recordId: this.recordId
      };
      publish(this.context, DEC_UPDATE_PAGE_LAYOUTS, msg);
    } else {
      this.updateEnvelopeConfiguration().then(window.navUtils.navigateToSObject.bind(this, this.recordId, null));
    }
  }

  handleRenameEnvelopeTemplate(message) {
    this.isDirty = true;
    this.updateEnvelopeConfiguration(null, {
      ...this.envelopeConfigurationData,
      name: message.name
    });
  }

  handleUpdateNotifications(message) {
    this.isDirty = true;
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
    this.isDirty = event.detail.data.isDirty || this.isDirty;
    this.updateLocalConfiguration({documents: event.detail.data.documents});
  }

  handleUpdateDocument(event) {
    this.isDirty = true;
    let documents = [...this.envelopeConfigurationData.documents];
    let indexToInsert = documents.length > 0 ? documents.length - 1 : 0;
    documents.splice(indexToInsert, 0, {...event.detail.data});
    this.updateLocalConfiguration({documents});
  }

  handleOnClickProgressStep(event) {
    this.updateProgressBar();
    this.updateEnvelopeConfiguration(event.detail.data);
  }

  setLoading(isTrue) {
    this.isLoading = isTrue ? true : false;
  }

  handleRenameTemplateDocument(message) {
    this.isDirty = true;
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
    this.isDirty = true;
    const documents = this.envelopeConfigurationData.documents.filter((d, i) => i !== message.index);
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, documents};
    this.contentDocumentIdsToDelete.push(message.contentDocumentId);
  }

  handleEmailChange({detail}) {
    this.isDirty = true;
    const {emailMessage = null, emailSubject = null} = detail.data;
    this.updateLocalConfiguration({
      emailMessage: emailMessage,
      emailSubject: emailSubject
    });
  }

  handleEmptyRecipient({detail}) {
    this.isEmptyRecipients = detail.data;
  }

  updateEnvelopeConfiguration(step, configurationData = this.envelopeConfigurationData) {
    const updatedConfiguration = this.getFilteredConfigurationData(configurationData);
    if (this.isDirty) {
      this.setLoading(true);
      return updateEnvelopeConfiguration({
        envelopeConfigurationJSON: updatedConfiguration,
        contentDocumentIdsToDelete: this.contentDocumentIdsToDelete
      })
        .then(result => {
          this.isDirty = false;
          this.currentStep = isEmpty(step) ? this.currentStep : step;
          this.envelopeConfigurationData = {
            ...result,
            documents: this.attachSourceFiles ? this.processTextSearchSourceFiles(result.documents, true) : result.documents
          };
          return Promise.resolve(true);
        })
        .catch(error => {
          showError(this.context, error, ERROR);
          return Promise.reject(false);
        })
        .finally(() => this.setLoading(false));
    } else {
      this.currentStep = isEmpty(step) ? this.currentStep : step;
      return Promise.resolve(true);
    }
  }

  // Process configuration data before updating it in server
  getFilteredConfigurationData(configurationData) {
    if (isEmpty(configurationData)) {
      return null;
    }
    const processedFields = {};

    let recipientsSelector = this.template.querySelector('c-recipients-config');
    if (!isEmpty(recipientsSelector)) {
      let fetchRecipients = recipientsSelector.fetchRecipients();
      if (fetchRecipients) {
        if (fetchRecipients.data) {
          processedFields.recipients = fetchRecipients.data.map(r => ({...r, id: null}));
        }
        if (fetchRecipients.isDirtyRecipients === true) {
          this.isDirty = true;
        }
      }
    } else {
      processedFields.recipients = configurationData.recipients.map(r => ({...r, id: null}));
    }

    const documents = this.attachSourceFiles
      ? this.processTextSearchSourceFiles(configurationData.documents, false)
      : configurationData.documents.filter(d => d.type === DOCUMENT_TYPE_TEMPLATE_DOCUMENT);

    processedFields.documents = documents.map(d => ({...d, id: null}));

    return JSON.stringify({
      ...configurationData,
      ...processedFields
    });
  }

  updateLocalEnvelopeConfigurationDocumentWriteBack(documentWriteBack) {
    let options = this.envelopeConfigurationData.options;
    options = {...options, documentWriteBack: documentWriteBack};
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, options: options};
    this.isDirty = true;
  }

  updateLocalEnvelopeConfigurationDataWriteBack(dataWriteBack) {
    let options = this.envelopeConfigurationData.options;
    options = {...options, envelopeEventUpdates: dataWriteBack};
    this.envelopeConfigurationData = {...this.envelopeConfigurationData, options: options};
    this.isDirty = true;
  }

  handleOnDocumentWriteBack(event) {
    this.updateLocalEnvelopeConfigurationDocumentWriteBack(event.detail.data);
  }

  handleOnDataWriteBack(event) {
    this.updateLocalEnvelopeConfigurationDataWriteBack(event.detail.data);
  }

  updateProgressBar() {
    let taggerStepUpdated = STEPS;
    if (!isEmpty(this.envelopeConfigurationData) &&
      !isEmpty(this.envelopeConfigurationData.documents) &&
      this.envelopeConfigurationData.documents.find((doc) => doc.type === DOCUMENT_TYPE_TEMPLATE_DOCUMENT)) {
      taggerStepUpdated[2].disabled = false;
      this.isTaggerDisabled = false;
    } else {
      taggerStepUpdated[2].disabled = true;
      this.isTaggerDisabled = true;
    }
    let progressSelector = this.template.querySelector('c-progress-bar');
    progressSelector.progressSteps(taggerStepUpdated);
  }

  processTextSearchSourceFiles(documents, extractText) {
    return documents.map((d) => {
      let doc = {...d};
      if (d.type === DOCUMENT_TYPE_SOURCE_FILES && !isEmpty(d.filter.filterBy)) {
        let updatedFilter = {...d.filter};
        if (extractText) { // obtain filter-by value from query text
          const startIndex = updatedFilter.filterBy.indexOf(FILE_NAME_FILTER_PREFIX) + FILE_NAME_FILTER_PREFIX.length;
          const endIndex = updatedFilter.filterBy.lastIndexOf(FILE_NAME_FILTER_SUFFIX);
          updatedFilter.filterBy = updatedFilter.filterBy.substring(startIndex, endIndex);
        } else { // convert filter-by value into query text
          updatedFilter.filterBy = format('{0}{1}{2}', FILE_NAME_FILTER_PREFIX, updatedFilter.filterBy, FILE_NAME_FILTER_SUFFIX);
        }
        doc.filter = updatedFilter;
      }
      return doc;
    });
  }
}