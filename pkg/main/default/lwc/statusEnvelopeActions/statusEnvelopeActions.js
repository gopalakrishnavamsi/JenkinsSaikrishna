import {LightningElement, api} from 'lwc';
import {format, genericEvent, isEmpty} from 'c/utils';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//labels
import sendReminderLabel from '@salesforce/label/c.SendReminder';
import voidEnvelopeLabel from '@salesforce/label/c.VoidEnvelope';
import reminderSentLabel from '@salesforce/label/c.ReminderSent';
import envelopeVoidedLabel from '@salesforce/label/c.EnvelopeVoided';
import cancelLabel from '@salesforce/label/c.cancel';
import voidEnvelopeHeaderLabel from '@salesforce/label/c.VoidEnvelopeHeader';
import voidReasonLabel from '@salesforce/label/c.VoidReason';
import voidEnvelopeConfirmationLabel from '@salesforce/label/c.VoidEnvelopeConfirmation';
import voidReasonLengthRemainingLabel from '@salesforce/label/c.VoidReasonLengthRemaining';

//actions
import voidEnvelope from '@salesforce/apex/StatusController.voidEnvelope';
import resendEnvelope from '@salesforce/apex/StatusController.resendEnvelope';

const REASON_MAX_LENGTH = 200;

export default class StatusEnvelopeActions extends LightningElement {

  @api envelopeId;

  voidReasonMaxLength = REASON_MAX_LENGTH;

  Labels = {
    sendReminderLabel: sendReminderLabel,
    voidEnvelopeLabel: voidEnvelopeLabel,
    cancelLabel: cancelLabel,
    voidEnvelopeHeaderLabel: voidEnvelopeHeaderLabel,
    voidReasonLabel: voidReasonLabel,
    voidEnvelopeConfirmationLabel: voidEnvelopeConfirmationLabel,
  };

  showVoidModal = false;
  privateVoidReason = null;
  showSpinner = false;

  get voidReason() {
    return this.privateVoidReason;
  }

  set voidReason(val) {
    this.privateVoidReason = val;
  }

  get isVoidDisabled() {
    return isEmpty(this.voidReason) || this.voidReason.match(/^ *$/) !== null;
  }

  get voidReasonLengthRemaining() {
    return format(voidReasonLengthRemainingLabel, !isEmpty(this.voidReason) ? this.voidReasonMaxLength - this.voidReason.length : this.voidReasonMaxLength);
  }

  handleReasonChange = (evt) => {
    this.voidReason = evt.target.value;
  };

  handleEnvelopeAction = ({detail}) => {
    let selectedAction = detail.value;
    switch (selectedAction) {
      case 'void':
        this.handleVoidEnvelope();
        break;
      case 'reminder':
        this.handleResendEnvelope();
        break;
      default:
        break;
    }
  };

  handleVoidEnvelope = () => {
    this.voidReason = null;
    this.showVoidModal = true;
  };

  handleResendEnvelope = () => {
    this.showSpinner = true;
    resendEnvelope({'envelopeId': this.envelopeId.value}).then(result => {
      this.showSpinner = false;
      if (result === true) {
        this.showNotification(reminderSentLabel, 'success');
        genericEvent.call(this, 'actioncompleted', null, false);
      }
    }).catch(error => {
      this.showSpinner = false;
      this.showNotification(error.body.message, 'error');
    });
  };

  closeVoidModal = () => {
    this.showVoidModal = false;
  };

  voidEnvelopeAction = () => {
    this.showSpinner = true;
    this.closeVoidModal();
    voidEnvelope({'envelopeId': this.envelopeId.value, 'reason': this.voidReason}).then(result => {
      this.showSpinner = false;
      if (result === true) {
        this.showNotification(envelopeVoidedLabel, 'success');
        genericEvent.call(this, 'actioncompleted', null, false);
      }
    }).catch(error => {
      this.showSpinner = false;
      this.showNotification(error.body.message, 'error');
    });
  };

  showNotification = (message, variant) => {
    this.dispatchEvent(
      new ShowToastEvent({
        message: message,
        variant: variant
      })
    );
  };

}