import {LightningElement, api} from 'lwc';
//Utils
import {
  LABEL,
  DEFAULT_EXPIRATION,
  REMINDER_OPTIONS,
  FILE_NAME_OPTIONS_DEFAULT,
  FILE_NAME_OPTIONS_COMBINED_DOCS,
  getDefaultNotifications,
  getDefaultOptions} from 'c/optionsUtils';

// Lightning message service - Publisher
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import DEC_UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/DecUpdateNotifications__c';
import {
  isEmpty,
  genericEvent,
} from 'c/utils';

export default class DecOptions extends LightningElement {
  @api notifications;
  @api options;
  @api recordId;
  documentWriteBackName;
  label = LABEL;
  context = createMessageContext();
  filenameOptions;
  isWriteBack;
  isCertificateOfCompletion = false;

  connectedCallback() {
    if (isEmpty(this.notifications)) {
      this.handleNotificationsChange({
        expires: true,
        expireAfterDays: DEFAULT_EXPIRATION
      });
    }
    this.filenameOptions = this.filenameChoices();
    this.documentWriteBackName = this.filenameOptions[0];
    this.isWriteBack = !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.nameFormat);
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  filenameChoices() {
    let nameOptions;
    let isCombineDocs = this.options.documentWriteBack.combineDocuments;
    if(isCombineDocs) {
      nameOptions = FILE_NAME_OPTIONS_COMBINED_DOCS;
    } else {
      nameOptions = FILE_NAME_OPTIONS_DEFAULT;
    }
    return nameOptions;
  }

  get reminderOptions() {
    return REMINDER_OPTIONS;
  }

  get reminder() {
    return !isEmpty(this.notifications) && !isEmpty(this.notifications.remindFrequencyDays) ? this.notifications.remindFrequencyDays : '';
  }

  get expiration() {
    return !isEmpty(this.notifications) && !isEmpty(this.notifications.expireAfterDays) ? this.notifications.expireAfterDays : null;
  }

  get envelopeExpires() {
    const delimiter = '{0}';
    const splitIndex = LABEL.expiresAfterSending.indexOf(delimiter);
    return LABEL.expiresAfterSending.substring(0, splitIndex);
  }

  get daysAfterSending() {
    const delimiter = '{0}';
    const splitIndex = LABEL.expiresAfterSending.indexOf(delimiter) + delimiter.length;
    return LABEL.expiresAfterSending.substring(splitIndex);
  }

  get documentWritebackOptions() {
    return !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.nameFormat);
  }

  get isCertificateOfCompletionEnabled() {
    let isCertificateOfCompletionSelected = !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.includeCertificateOfCompletion);
    return isCertificateOfCompletionSelected || this.isCertificateOfCompletion;
  }

  get documentWritebackCombineDocuments() {
    let combineDoc = !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.combineDocuments);
    return  combineDoc ? this.options.documentWriteBack.combineDocuments : false;
  }

  get documentWritebackFilename() {
    let nameFormat = !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.nameFormat);
    this.documentWriteBackName = nameFormat ? this.options.documentWriteBack.nameFormat : this.filenameOptions[0].value;
    return this.documentWriteBackName;
  }

  get documentWritebackCertificateOfCompletion() {
    let coc = !isEmpty(this.options) &&
        !isEmpty(this.options.documentWriteBack) &&
        !isEmpty(this.options.documentWriteBack.includeCertificateOfCompletion);
    this.isCertificateOfCompletion = coc ? this.options.documentWriteBack.includeCertificateOfCompletion : false;
    return this.isCertificateOfCompletion;
  }

  handleNotificationsChange(updatedFields = {}) {
    const currentNotifications = this.notifications || getDefaultNotifications();
    const message = {
      notifications: {
        ... currentNotifications,
        ... updatedFields
      }
    };
    publish(this.context, DEC_UPDATE_NOTIFICATIONS, message);
  }

  handleReminderChange(event) {
    event.preventDefault();
    const hasEmptyValue = isEmpty(event.target.value);
    this.handleNotificationsChange({
      remind: !hasEmptyValue,
      remindFrequencyDays: hasEmptyValue ? null : parseInt(event.target.value)
    });
  }

  handleExpirationChange(event) {
    event.preventDefault();
    const filteredValue = event.target.value.replace(/[^0-9]/g, '');
    
    // Expiration value is limited to 3 digits
    event.target.value = isEmpty(filteredValue) ? null : filteredValue.substring(0, 3);

    if (!isEmpty(event.target.value)) {
      this.handleNotificationsChange({
        expires: true,
        expireAfterDays: parseInt(event.target.value)
      });
    }
  }

  handleExpirationBlur(event) {
    event.preventDefault();

    // If no expiration value is entered, use default expiration value
    if (isEmpty(event.target.value)) {
      this.handleNotificationsChange({
        expires: true,
        expireAfterDays: DEFAULT_EXPIRATION
      });
    }
  }

  handleOnChangeOfDocumentWritebackOptions(event) {
    this.isWriteBack = event.target.checked;
    let documentWriteBackUpdated = this.options.documentWriteBack;
    if(this.isWriteBack) {
      documentWriteBackUpdated =
          {...documentWriteBackUpdated,
            linkedEntityId: this.recordId,
            nameFormat: this.filenameOptions[0].value};
    } else {
      let defaultOptions = getDefaultOptions().documentWriteBack;
      documentWriteBackUpdated =
        {...defaultOptions,
          includeCertificateOfCompletion : this.isCertificateOfCompletion,
          linkedEntityId: this.isCertificateOfCompletion ? this.recordId : null};
      this.isCustomFileName = false;
    }
    genericEvent.call(this, 'documentwriteback', documentWriteBackUpdated, false);
  }

  handleOnChangeOfCombinedDocumentWritebackOptions(event) {
    let combineDocuments = event.target.checked;
    let documentWriteBackUpdated = this.options.documentWriteBack;
    documentWriteBackUpdated = {...documentWriteBackUpdated, combineDocuments: combineDocuments};
    if(this.isCertificateOfCompletion === false) {
      this.setFilenameOptions(this.isCertificateOfCompletion, documentWriteBackUpdated);
    }
    documentWriteBackUpdated = {...documentWriteBackUpdated, nameFormat: this.documentWriteBackName};
    genericEvent.call(this, 'documentwriteback', documentWriteBackUpdated, false);
  }

  handleFilenameChange(event) {
    let updatedFileName = event.target.value;
    let documentWriteBackUpdated = this.options.documentWriteBack;
    documentWriteBackUpdated = {...documentWriteBackUpdated, nameFormat: updatedFileName};
    genericEvent.call(this, 'documentwriteback', documentWriteBackUpdated, false);
  }

  handleCertificateOfCompletionChange(event) {
    this.isCertificateOfCompletion = event.target.checked;
    let documentWriteBackUpdated = this.options.documentWriteBack;
    documentWriteBackUpdated =
        {...documentWriteBackUpdated,
        includeCertificateOfCompletion: this.isCertificateOfCompletion};
    genericEvent.call(this, 'documentwriteback', documentWriteBackUpdated, false);
  }

  setFilenameOptions(isCertificateOfCompletion, documentWriteBackUpdated) {
    this.filenameOptions =
        documentWriteBackUpdated.combineDocuments ? FILE_NAME_OPTIONS_COMBINED_DOCS : FILE_NAME_OPTIONS_DEFAULT;
    this.documentWriteBackName = this.filenameOptions[0].value;
  }
}