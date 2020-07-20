import {LightningElement, api} from 'lwc';
import {isEmpty} from 'c/utils';

export default class Lwctoast extends LightningElement {
  @api
  showToast = false;

  @api
  mode;

  @api
  message;

  @api
  detail;

  @api
  close() {
    this.showToast = false;
  }

  @api
  show() {
      this.showToast = true;
  }

  get toastClass() {
    let toastClass;

    switch (this.mode) {
      case 'success':
        toastClass = 'slds-notify slds-notify_toast slds-theme_success';
        break;

      case 'warning':
        toastClass = 'slds-notify slds-notify_toast slds-theme_warning';
        break;

      case 'error':
        toastClass = 'slds-notify slds-notify_toast slds-theme_error';
        break;
    }

    return toastClass;
  }

  get toastIcon() {
    let toastIcon;

    switch (this.mode) {
      case 'success':
        toastIcon = 'utility:success';
        break;

      case 'warning':
        toastIcon = 'utility:warning';
        break;

      case 'error':
        toastIcon = 'utility:error';
        break;
    }

    return toastIcon;
  }

  get detailNotEmpty() {
    return !isEmpty(this.detail);
  }

}