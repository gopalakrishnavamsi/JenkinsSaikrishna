import {LightningElement, api} from 'lwc';
import {Recipient, LookupRecipient, RelatedRecipient, Types, Labels} from 'c/recipientUtils';
import {isEmpty, proxify} from 'c/utils';
const DEFAULT_SELECTED_TYPE = Types.LookupRecipient.value;

export default class DecRecipientsModal extends LightningElement {

  Labels = Labels;

  @api
  sourceObject;

  Types = Types;

  selectedType = DEFAULT_SELECTED_TYPE;

  @api
  isOpen;

  privateRecipient = this.convertRecipientType({});

  @api
  routingOrder = 1;

  @api
  handleClose;

  @api
  handleSave;

  isValid = false;

  @api
  set recipient(val) {
    this.privateRecipient = !isEmpty(val) ? val : this.convertRecipientType({});
    this.isValid = this.privateRecipient.isValid;
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
    this.selectedType = DEFAULT_SELECTED_TYPE;
    this.recipient = null;
  };

  closeModal = () => {
    if (this.handleClose) this.handleClose();
    this.recipient = null;
  };

  handleTypeChange = ({detail}) => {
    if (this.selectedType === detail.name) return;
    this.selectedType = detail.name;
    this.recipient = !isEmpty(this.recipient) ? this.convertRecipientType(this.recipient) : null;
    this.isValid = false;
  };

  handleValidationChange = ({detail}) => {
    this.isValid = detail;
  };

  convertRecipientType({note = null}) {
    let result;

    switch (this.selectedType) {
      case this.Types.LookupRecipient.value:
        result = new LookupRecipient(
          null,
          null,
          this.routingOrder,
          {
            note
          }
        );
        break;
      case this.Types.RelatedRecipient.value:
        result = new RelatedRecipient(
          null,
          null,
          null,
          this.routingOrder,
          null,
          {
            note
          }
        );
        break;
      default:
        result = new Recipient(
          {
            note
          },
          null,
          this.routingOrder
        );
        break;
    }
    return proxify(result);
  }
}