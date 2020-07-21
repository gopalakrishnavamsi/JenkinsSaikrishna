import {LightningElement, api} from 'lwc';
//Utils
import {
  LABEL,
  DEFAULT_EXPIRATION,
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

  connectedCallback() {
    if (isEmpty(this.notifications)) {
      this.handleNotificationsChange({
        expires: true,
        expireAfterDays: DEFAULT_EXPIRATION
      });
    }
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get reminderOptions() {
    return REMINDER_OPTIONS;
  }

  get reminder() {
    if (!isEmpty(this.selectedReminder)) {
      return this.selectedReminder;
    } else {
      return !isEmpty(this.envelope.notifications) && !isEmpty(this.envelope.notifications.remindFrequencyDays) ? this.envelope.notifications.remindFrequencyDays : '';
    }
  }

  set reminder(value) {
    this.selectedReminder = value;
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
    this.expirationDate = new Date();
    if (expDays !== null) {
      this.expirationDate.setDate(this.expirationDate.getDate() + expDays);
    }
    return formatDate(this.expirationDate);
  }

  set formattedExpirationDate(value) {
    this.expirationDate = value;
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
        updatedFields
      }
    };
    publish(this.context, UPDATE_NOTIFICATIONS, message);
  }

  handleReminderChange(event) {
    this.reminder = parseInt(event.target.value);
    const hasEmptyValue = isEmpty(event.target.value);
    let updatedNotifications = {
      ...this.notifications,
      'remindFrequencyDays': parseInt(event.target.value),
      'remind': !hasEmptyValue
    };
    const message = {
      notifications: updatedNotifications
    };
    publish(this.context, UPDATE_NOTIFICATIONS, message);
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
    let filteredValue = isEmpty(event.target.value) ? null : event.target.value.replace(/[^0-9]/g, '');
    // Expiration value is limited to 3 digits
    let expirationValue = isEmpty(filteredValue) ? null : filteredValue.substring(0, 3);
    if (expirationValue !== null) {
      let updatedExpirationDate = new Date();
      updatedExpirationDate.setDate(updatedExpirationDate.getDate() + parseInt(expirationValue));
      this.formattedExpirationDate = formatDate(updatedExpirationDate);
    }
    let expires = isEmpty(expirationValue) ? false : true;
    this.updateExpiration(expires, expirationValue);
  }

  updateExpiration(expires, expireAfterDays) {
    let updatedNotifications = {
      ...this.notifications,
      'expires': expires,
      'expireAfterDays': expireAfterDays
    };
    const message = {
      notifications: updatedNotifications
    };
    publish(this.context, UPDATE_NOTIFICATIONS, message);
  }
}