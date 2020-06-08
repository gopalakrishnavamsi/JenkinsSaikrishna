import {LightningElement, api} from 'lwc';
import {Recipient, LookupRecipient, RelatedRecipient, Types, Labels} from 'c/recipientUtils';
import {isEmpty, proxify} from 'c/utils';

export default class DecRecipientsModal extends LightningElement {

  Labels = Labels;

  @api
  sourceObject;

  Types = Types;

  selectedType = this.Types.LookupRecipient.value;

  @api
  isOpen;

  privateRecipient = this.convertRecipientType({});;

  @api
  routingOrder = 1;

  @api
  handleClose;

  @api
  handleSave;

  @api
  set recipient(val) {
    this.privateRecipient = val;
  }

  get recipient() {
    return this.privateRecipient;
  }

  get isNew() {
    return isEmpty(this.recipient);
  }

  saveRecipient = () => {
    if (this.handleSave) this.handleSave(this.privateRecipient);
    this.privateRecipient = this.convertRecipientType({});
  }

  closeModal = () => {
    if (this.handleClose) this.handleClose();
    this.privateRecipient = this.convertRecipientType({});
  }

  handleTypeChange({ detail }) {
    if (this.selectedType === detail.name) return;
    this.selectedType = detail.name;
    this.privateRecipient = !isEmpty(this.privateRecipient) ? this.convertRecipientType(this.privateRecipient) : this.convertRecipientType({});
  }

  convertRecipientType({ note = null, authentication = null }) {
    if (!isEmpty(this.recipient) && this.selectedType === this.recipient.recipientType) return this.recipient;

    let result;

    switch(this.selectedType) {
      case this.Types.LookupRecipient.value:
        result = new LookupRecipient(
          null,
          null,
          this.routingOrder,
          {
              authentication,
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
              authentication,
              note
          }                   
        )
        break;
      default:
        result = new Recipient(
          {
              authentication,
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