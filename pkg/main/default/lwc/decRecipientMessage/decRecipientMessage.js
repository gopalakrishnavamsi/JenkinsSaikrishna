import {LightningElement, api} from 'lwc';
import {genericEvent} from 'c/utils';
import emailSubjectLabel from '@salesforce/label/c.EmailSubject';
import emailMessageLabel from '@salesforce/label/c.EmailMessage';
import messageToAllHeaderLabel from '@salesforce/label/c.MessageToAllHeader';
import messageToAllDescriptionLabel from '@salesforce/label/c.MessageToAllDescription';

export default class DecRecipientMessage extends LightningElement {

  @api emailSubject = null;
  @api emailMessage = null;

  Labels = {
    emailSubjectLabel,
    emailMessageLabel,
    messageToAllHeaderLabel,
    messageToAllDescriptionLabel
  };

  handleEmailChange = ({target}) => {
    const paramName = target.name;
    const paramValue = target.value;
    let payLoad = {
      emailSubject: this.emailSubject,
      emailMessage: this.emailMessage,
    };
    payLoad[paramName] = paramValue;
    genericEvent.call(this, 'emailchange', payLoad, false);
  };
}