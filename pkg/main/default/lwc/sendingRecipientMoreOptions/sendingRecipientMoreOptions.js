import {LightningElement, api} from 'lwc';
//Utils
import {LABEL, DEFAULT_EXPIRATION, REMINDER_OPTIONS, getDefaultNotifications} from 'c/optionsUtils';

//Lightning message service - Publisher
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/UpdateNotifications__c';
import {isEmpty} from 'c/utils';

export default class SendingRecipientMoreOptions extends LightningElement {
  @api notifications;
  @api envelope;
  context = createMessageContext();
  label = LABEL;
  selectedReminder;

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
    return !isEmpty(this.envelope.notifications) && !isEmpty(this.envelope.notifications.expireAfterDays) ? this.envelope.notifications.expireAfterDays : null;
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

  handleExpirationChange(event) {
    let filteredValue = isEmpty(event.target.value) ? null : event.target.value.replace(/[^0-9]/g, '');
    // Expiration value is limited to 3 digits
    let expirationValue = isEmpty(filteredValue) ? null : filteredValue.substring(0, 3);
    let updatedNotifications = {
      ...this.notifications,
      'expires': isEmpty(expirationValue) ? false : true,
      'expireAfterDays': expirationValue
    };
    const message = {
      notifications: updatedNotifications
    };
    publish(this.context, UPDATE_NOTIFICATIONS, message);

  }

}