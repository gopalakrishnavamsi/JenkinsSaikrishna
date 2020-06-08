import {LightningElement, api} from 'lwc';
//Utils
import {LABEL, DEFAULT_EXPIRATION, REMINDER_OPTIONS, getDefaultNotifications} from 'c/optionsUtils';

// Lightning message service - Publisher
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';
import DEC_UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/DecUpdateNotifications__c';
import { isEmpty } from 'c/utils';

export default class DecOptions extends LightningElement {
  @api notifications;
  label = LABEL;
  context = createMessageContext();

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
}