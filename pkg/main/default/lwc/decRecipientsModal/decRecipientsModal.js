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

  routingOrder = 1;

  @api
  handleClose;

  @api
  handleSave;

  isValid = false;

  @api
  set recipient(val) {
    this.privateRecipient = !isEmpty(val) ? proxify(val) : this.convertRecipientType({});
    if (!isEmpty(val)) this.selectedType = val.recipientType
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
    this.recipient = null;
    this.selectedType = DEFAULT_SELECTED_TYPE;
  };

  closeModal = () => {
    if (this.handleClose) this.handleClose();
    this.recipient = null;
  };

  handleTypeChange = ({detail}) => {
    if (this.selectedType === detail.name) return;
    this.recipient = !isEmpty(this.recipient) ? this.convertRecipientType(this.recipient, detail.name) : null;
    this.selectedType = detail.name;
    this.isValid = false;
  };

  handleValidationChange = ({detail}) => {
    this.isValid = detail;
  };

  convertRecipientType({note = null}, type = DEFAULT_SELECTED_TYPE) {
    if (isEmpty(type)) return null;
    
    let result;

    switch (type) {
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