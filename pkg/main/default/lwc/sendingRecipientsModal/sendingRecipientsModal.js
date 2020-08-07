import {LightningElement, api} from 'lwc';
import {Recipient, Types, Labels, Actions} from 'c/recipientUtils';
import {isEmpty, proxify} from 'c/utils';
import DuplicateRowLabel from '@salesforce/label/c.DuplicateRow';

const DEFAULT_SELECTED_TYPE = Types.EntityLookupSending.value;

export default class SendingRecipientsModal extends LightningElement {
  Labels = {
    ...Labels,
    DuplicateRowLabel
  };

  @api
  sourceObject;

  @api
  readOnly = false;

  Types = Types;

  selectedType = DEFAULT_SELECTED_TYPE;

  @api
  isOpen;

  privateRecipient = null;

  routingOrder = 1;

  @api
  handleClose;

  @api
  handleSave;

  @api isDuplicate;

  showDuplicateRecipientError = false;

  isValid = false;

  connectedCallback() {
    if (isEmpty(this.privateRecipient)) this.privateRecipient = this.convertRecipientType({});
  }

  @api
  set recipient(val) {
    this.privateRecipient = !isEmpty(val) ? proxify(val) : this.convertRecipientType({});
    this.selectedType = !isEmpty(val) ? val.recipientType : DEFAULT_SELECTED_TYPE;
    this.isValid = this.privateRecipient.isSendingReady;
  }

  get recipient() {
    return this.privateRecipient;
  }

  get isSaveDisabled() {
    return !this.isValid;
  }

  get isNew() {
    return isEmpty(this.recipient);
  }

  saveRecipient = () => {
    if (this.handleSave) this.handleSave(this.privateRecipient, false);
    this.recipient = null;
  };

  saveRecipientAndOpenNew = () => {
    if (this.handleSave) this.handleSave(this.privateRecipient, true);
    this.recipient = null;
  };

  closeModal = () => {
    if (this.handleClose) this.handleClose();
    this.recipient = null;
    this.showDuplicateRecipientError = false;
  };

  handleTypeChange = ({detail}) => {
    if (this.selectedType === detail.name) return;
    this.recipient = !isEmpty(this.recipient) ? this.convertRecipientType(this.recipient, detail.name, this.recipient ? this.recipient.isPlaceHolder : false) : null;
    this.selectedType = detail.name;
    this.isValid = false;
  };

  handleValidationChange = ({detail}) => {
    this.showDuplicateRecipientError = this.isDuplicate(this.recipient);
    this.isValid = detail && !this.showDuplicateRecipientError;
  };

  convertRecipientType({note = null, envelopeRecipientId = null, role = null, sequence = null, hasTemplateAuthentication = false, hasTemplateNote = false}, type = DEFAULT_SELECTED_TYPE, isPlaceHolder = false) {
    if (isEmpty(type)) return null;
    return proxify(
      new Recipient(
        {
          note,
          sequence,
          envelopeRecipientId,
          isPlaceHolder,
          hasTemplateAuthentication,
          hasTemplateNote,
          type : this.readOnly && !isPlaceHolder ? Actions.CarbonCopy.value : Actions.Signer.value
        },
        role,
        this.routingOrder
      )
    );
  }
}