import {LightningElement, api} from 'lwc';
//Utils
import {
  LABEL,
  DEFAULT_REMINDER,
  REMINDER_OPTIONS,
  getDefaultNotifications,
} from 'c/optionsUtils';
//Lightning message service - Publisher
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
import UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/UpdateNotifications__c';
// Publisher
import ERROR from '@salesforce/messageChannel/Error__c';
import {
  isEmpty,
  formatDate
} from 'c/utils';

export default class SendingRecipientMoreOptions extends LightningElement {
  @api notifications;
  @api envelope;
  context = createMessageContext();
  label = LABEL;
  selectedReminder;
  expirationDate;
  expirationDays;

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get reminderOptions() {
    return REMINDER_OPTIONS;
  }

  get reminder() {
    return !isEmpty(this.notifications) && !isEmpty(this.notifications.remindFrequencyDays) ? this.notifications.remindFrequencyDays : DEFAULT_REMINDER;
  }

  get expiration() {
    if (!isEmpty(this.expirationDays)) {
      return this.expirationDays;
    }
    return !isEmpty(this.envelope.notifications) && !isEmpty(this.envelope.notifications.expireAfterDays) ?
      this.envelope.notifications.expireAfterDays : null;
  }

  set expiration(value) {
    this.expirationDays = value;
  }

  get formattedExpirationDate() {
    if (!isEmpty(this.expirationDate)) {
      return this.expirationDate;
    }
    let expDays = !isEmpty(this.envelope.notifications) && !isEmpty(this.envelope.notifications.expireAfterDays) ?
      this.envelope.notifications.expireAfterDays : null;
    let expirationDate = new Date();
    if (!isEmpty(expDays)) {
      expirationDate.setDate(expirationDate.getDate() + expDays);
    }
    return formatDate(expirationDate);
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

  handleNotificationsChange(updatedFields = {}) {
    const currentNotifications = this.notifications || getDefaultNotifications();
    const message = {
      notifications: {
        ...currentNotifications,
        ...updatedFields
      }
    };
    publish(this.context, UPDATE_NOTIFICATIONS, message);
  }

  handleReminderChange(event) {
    event.preventDefault();
    const remindFrequencyDays = parseInt(event.target.value);
    this.handleNotificationsChange({
      remind: remindFrequencyDays > 0,
      remindFrequencyDays
    });
  }

  handleExpirationDateChange(event) {
    let dateChanged = event.target.value;
    let expDate = new Date(dateChanged);
    let today = new Date();
    let diffDays = null;
    if (expDate < today) {
      this.expiration = null;
      const msg = {
        errorMessage: this.label.expirationDateError
      };
      publish(this.context, ERROR, msg);
    } else {
      const diffTime = Math.abs(expDate - today);
      diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      this.expiration = diffDays;
    }
    let expires = !isEmpty(this.expiration) ? true : false;
    this.updateExpiration(expires, diffDays);
  }

  handleExpirationChange(event) {
    if (event.target.value < 0) {
      const msg = {
        errorMessage: this.label.expirationDateError
      };
      publish(this.context, ERROR, msg);
      return;
    }
    let filteredValue = isEmpty(event.target.value) ? null : event.target.value.replace(/[^0-9]/g, '');
    // Expiration value is limited to 3 digits
    let expirationValue = isEmpty(filteredValue) ? null : filteredValue.substring(0, 3);
    if (expirationValue !== null) {
      let updatedExpirationDate = new Date();
      updatedExpirationDate.setDate(updatedExpirationDate.getDate() + parseInt(expirationValue));
      this.expirationDate = formatDate(updatedExpirationDate);
    }
    let expires = isEmpty(expirationValue) ? false : true;
    this.updateExpiration(expires, parseInt(expirationValue));
  }

  updateExpiration(expires, expireAfterDays) {
    this.handleNotificationsChange({
      expires,
      expireAfterDays
    });
  }
}