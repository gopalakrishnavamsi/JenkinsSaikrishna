import { format } from 'c/utils';

//custom labels
import options from '@salesforce/label/c.Options';
import optionsInfoText from '@salesforce/label/c.OptionsInfoText';
import helpVideoText from '@salesforce/label/c.DecOptionsVideoText';
import helpVideoLength from '@salesforce/label/c.DecOptionsVideoLength';
import helpVideoLink from '@salesforce/label/c.DecOptionsVideoLink';
import documentWriteback from '@salesforce/label/c.DocumentWriteback';
import opportunityStage from '@salesforce/label/c.OpportunityStage';
import reminders from '@salesforce/label/c.Reminders';
import automaticReminders from '@salesforce/label/c.AutomaticReminders';
import expiration from '@salesforce/label/c.Expiration';
import doNotRemind from '@salesforce/label/c.DoNotRemind';
import everyDay from '@salesforce/label/c.EveryDay';
import everyNumberOfDays from '@salesforce/label/c.EveryNumberOfDays';
import expiresAfterSending from '@salesforce/label/c.ExpiresAfterSending';

const LABEL = {
  options,
  optionsInfoText,
  helpVideoText,
  helpVideoLength,
  helpVideoLink,
  documentWriteback,
  opportunityStage,
  reminders,
  automaticReminders,
  expiration,
  doNotRemind,
  everyDay,
  everyNumberOfDays,
  expiresAfterSending
};

const DEFAULT_EXPIRATION = 90;

const REMINDER_OPTIONS = [
  {
    label: LABEL.doNotRemind,
    value: ''
  },
  {
    label: LABEL.everyDay,
    value: 1
  },
  {
    label: format(LABEL.everyNumberOfDays, 2),
    value: 2
  },
  {
    label: format(LABEL.everyNumberOfDays, 3),
    value: 3
  },
  {
    label: format(LABEL.everyNumberOfDays, 4),
    value: 4
  },
  {
    label: format(LABEL.everyNumberOfDays, 5),
    value: 5
  },
  {
    label: format(LABEL.everyNumberOfDays, 6),
    value: 6
  },
  {
    label: format(LABEL.everyNumberOfDays, 7),
    value: 7
  }
];

const getDefaultNotifications = () => ({
  remind: false,
  remindAfterDays: null,
  remindFrequencyDays: null,
  expires: false,
  expireAfterDays: null,
  expireWarnDays: null
});

export {
  LABEL,
  DEFAULT_EXPIRATION,
  REMINDER_OPTIONS,
  getDefaultNotifications
}