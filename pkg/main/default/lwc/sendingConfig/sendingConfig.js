import {LightningElement, api} from 'lwc';

// Publisher
import ERROR from '@salesforce/messageChannel/Error__c';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext,
  publish
} from 'lightning/messageService';
import UPDATE_NOTIFICATIONS from '@salesforce/messageChannel/UpdateNotifications__c';

// utility functions
import {isEmpty, proxify, subscribeToMessageChannel, showError} from 'c/utils';
import {
  LABEL,
  PROGRESS_STEP,
  MIN_STEP,
  MAX_STEP,
  STEPS,
  OPERATION,
  getDocumentsForSending
} from 'c/sendingUtils';

//apex methods
import sendEnvelope from '@salesforce/apex/SendingController.sendEnvelope';
import getTaggerUrl from '@salesforce/apex/SendingController.getTaggerUrl';
import deleteDocument from '@salesforce/apex/SendingController.deleteDocument';
import deleteIncompleteEnvelope from '@salesforce/apex/SendingController.deleteIncompleteEnvelope';


export default class SendingConfig extends LightningElement {

  @api recordId;
  @api recordName;
  @api envelope;
  // Flag to determine ability to modify docs/recipients
  // This may need to be divided into different flags later
  @api forbidEnvelopeChanges;
  @api defaultRoles;
  @api files;
  @api sendNow;

  isLoading = false;
  label = LABEL;
  currentStep = MIN_STEP;

  context = createMessageContext();
  privateDocuments = null;
  privateRecipients = null;
  privateNotifications = null;
  //Todo, Use Draft envelope
  envelope;
  emailSubject;
  emailMessage;
  isEmptyRecipients = false;

  // Temporary recipients list for testing online editor sending flow
  // testRecipients = [{'email':'rose@edge.com','isSigningGroup':false,'name':'Rose Gonzalez','phone':'(512) 757-9340','readOnly':false,'required':false,'signNow':false,'source':{'id':'0032F00000Zy9DEQAZ','isValid':true,'label':'Contact','name':'Rose Gonzalez','parent':{'id':'0012F00000dlx9XQAQ','isValid':true,'label':'Account','name':'Edge Communications','typeName':'Account'},'typeName':'Contact'},'type':'Signer','templateId':null,'emailSettings':{},'authentication':{},'role':{}}];

  connectedCallback() {
    this.steps = this.sendNow ? STEPS.filter(s => s.value !== PROGRESS_STEP.PREPARE_AND_SEND) : STEPS;

    this.updateNotificationsSubscription = subscribeToMessageChannel(
      this.context,
      this.updateNotificationsSubscription,
      UPDATE_NOTIFICATIONS,
      this.handleUpdateNotifications.bind(this)
    );

    this.emailSubject = this.envelope && !isEmpty(this.envelope.emailSubject) ? this.envelope.emailSubject : this.label.defaultEmailSubject;
    this.emailMessage = this.envelope && !isEmpty(this.envelope.emailMessage) ? this.envelope.emailMessage : this.label.defaultEmailMessage;
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  get isFirstStep() {
    return this.currentStep === MIN_STEP;
  }

  get isFinalStep() {
    return this.currentStep === MAX_STEP;
  }

  get nextStepButtonText() {
    return (this.currentStep === PROGRESS_STEP.RECIPIENTS || this.currentStep === PROGRESS_STEP.PREPARE_AND_SEND)
    && this.sendNow ? this.label.send : this.label.next;
  }

  get showEmailMessage() {
    return this.currentStep === PROGRESS_STEP.RECIPIENTS && !this.isEmptyRecipients;
  }

  /*
      Placeholder for sending immediately or navigating to tagger page.
      TODO: Discuss and finalize Prepare & Send loading behavior
  */
  get taggerLoadingMessage() {
    return this.sendNow ? 'Sending envelope...' : 'Preparing to send for signature...';
  }

  @api
  get documents() {
    return this.privateDocuments;
  }

  set documents(docs) {
    this.privateDocuments = isEmpty(docs) ? null : proxify(docs);
  }

  @api
  get notifications() {
    return this.privateNotifications;
  }

  set notifications(notifs) {
    this.privateNotifications = isEmpty(notifs) ? null : proxify(notifs);
  }

  @api
  get recipients() {
    return this.privateRecipients;
  }

  set recipients(recs) {
    this.privateRecipients = isEmpty(recs) ? null : proxify(recs);
  }

  get documentsStep() {
    return this.currentStep === PROGRESS_STEP.DOCUMENTS;
  }

  get recipientsStep() {
    return this.currentStep === PROGRESS_STEP.RECIPIENTS;
  }

  handleEmailChange = ({detail}) => {
    const {emailMessage = null, emailSubject = null} = detail.data;
    this.emailMessage = emailMessage;
    this.emailSubject = emailSubject;
  };

  handleEmptyRecipient({detail}) {
    this.isEmptyRecipients = detail.data;
  }

  handleOnClickProgressStep(event) {
    let toStep = event.detail.data;

    if (this.currentStep === PROGRESS_STEP.DOCUMENTS) {
      let documentsSelector = this.template.querySelector('c-sending-documents');
      if (!isEmpty(documentsSelector)) {
        let documents = documentsSelector.fetchDocuments();
        if (documents) this.documents = documents.data;
      }
    }

    if (this.currentStep === PROGRESS_STEP.RECIPIENTS) {
      let recipientsSelector = this.template.querySelector('c-recipients-config');
      if (!isEmpty(recipientsSelector)) {
        let recipients = recipientsSelector.fetchRecipients();
        if (recipients) this.recipients = recipients.data;
      }
    }

    if (toStep === OPERATION.BACK) {
      toStep = (parseInt(this.currentStep, 10) - 1).toString();
    } else if (toStep === OPERATION.NEXT) {
      toStep = (parseInt(this.currentStep, 10) + 1).toString();
    }

    if (!this.validateCurrentStep(toStep)) {
      return;
    }
    this.currentStep = toStep;

    if (this.currentStep === PROGRESS_STEP.PREPARE_AND_SEND) {
      const draftEnvelope = this.createDraftEnvelope();
      this.prepareAndSendEnvelope(draftEnvelope);
    }
  }

  // TODO: Inquire about validation designs. This structure is a (temporary) placeholder
  validateCurrentStep(toStep) {
    let valid = false;
    const sameStep = this.currentStep === toStep;
    if (this.currentStep === PROGRESS_STEP.DOCUMENTS && !sameStep) {
      valid = !isEmpty(this.privateDocuments.find(doc => doc.selected));
      if (!valid) {
        this.showError(this.label.atLeastOneDocumentIsRequired);
      }
    } else if (this.currentStep === PROGRESS_STEP.RECIPIENTS && !sameStep) {
      valid = this.recipients.every(r => r.isSendingReady);
      if (!valid) this.showError(this.label.undefinedRecipient);
    } else if (this.currentStep === PROGRESS_STEP.PREPARE_AND_SEND && !sameStep) {
      valid = true;
    }
    return valid;
  }

  handleExitWorkflow() {
    this.handleDeleteIncompleteEnvelope();
    this.dispatchEvent(new CustomEvent('sendcomplete', {
      detail: {status: 'canceled'}
    }));
    const isOnlineEditor = this.forbidEnvelopeChanges && this.sendNow;
    if (isOnlineEditor) {
      this.deleteSCMDocument()
        .catch(error => showError(this.context, error, ERROR));
    } else {
      window.navUtils.navigateToSObject(this.recordId);
    }
  }

  handleDeleteIncompleteEnvelope() {
    deleteIncompleteEnvelope({envelopeId: this.envelope.id})
      .then()
      .catch(error => showError(this.context, error, ERROR));
  }

  deleteSCMDocument() {
    return deleteDocument({scmFile: isEmpty(this.files) ? null : this.files[0]})
      .then(() => window.navUtils.navigateToSObject(this.recordId));
  }

  createDraftEnvelope() {
    const documents = getDocumentsForSending(this.privateDocuments);
    const recipients = this.privateRecipients;
    return {
      ...this.envelope,
      documents,
      recipients,
      notifications: this.privateNotifications,
      emailSubject: this.emailSubject,
      emailMessage: this.emailMessage
    };
  }

  prepareAndSendEnvelope(envelope) {
    this.isLoading = true;
    const eventProperties = {
      'Documents': envelope && envelope.documents ? envelope.documents.length : 0,
      'Recipients': envelope && envelope.recipients ? envelope.recipients.length : 0,
      'Using Template': envelope && envelope.documents && envelope.documents.some(d => d.type === 'Template'),
      'Using HTML': envelope && envelope.documents && envelope.documents.some(d => d.extension === 'adf' || d.extension === 'html' || d.extension === 'htm'),
      'Using SpringCM': envelope && envelope.documents && envelope.documents.some(d => d.type === 'SCM'),
      'Send Now': this.sendNow
    };

    sendEnvelope({
      envelopeJson: JSON.stringify(envelope),
      sendNow: this.sendNow,
      updateNow: true
    })
      .then(result => {
        if (this.sendNow) return this.deleteSCMDocument();

        return this.navigateToTagger(
          result.id,
          result.docuSignId,
          result.source ? result.source.id : null);
      })
      .then(() => {
        this.dispatchEvent(new CustomEvent('sendcomplete', {
          detail: {
            properties: eventProperties,
            status: 'success'
          }
        }));
      })
      .catch(error => {
        this.dispatchEvent(new CustomEvent('sendcomplete', {
          detail: {
            properties: eventProperties,
            status: 'failure'
          }
        }));
        showError(this.context, error, ERROR);
      })
      .finally(() => this.isLoading = false);
  }

  navigateToTagger(envelopeId, docuSignId, sourceId) {
    return getTaggerUrl({
      envelopeId: envelopeId,
      docuSignId: docuSignId ? docuSignId.value : null,
      sourceId: sourceId
    })
      .then(result => {
        window.navUtils.navigateToUrl(result);
      });
  }

  showError(errorMessage) {
    publish(this.context, ERROR, {errorMessage});
  }

  handleUpdateNotifications(message) {
    this.privateNotifications = message.notifications;
  }
}

