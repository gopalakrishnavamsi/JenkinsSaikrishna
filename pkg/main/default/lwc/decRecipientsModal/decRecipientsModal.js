import {LightningElement, api} from 'lwc';
import {Recipient, LookupRecipient, RelatedRecipient, Types, Labels} from 'c/recipientUtils';
import {isEmpty} from 'c/utils';

export default class DecRecipientsModal extends LightningElement {

  Labels = Labels;

  @api
  sourceObject;

  Types = Types;

  @api
  recipient = null;

  selectedType = this.Types.LookupRecipient.value;

  @api
  isOpen;

  privateRecipient = null;

  @api
  routingOrder = 1;

  @api
  handleClose;

  @api
  handleSave;
    
  connectedCallback() {
    //Edit Flow
    if (!isEmpty(this.recipient) && isEmpty(this.privateRecipient)) {
      this.privateRecipient = this.recipient;
    } else if (isEmpty(this.recipient)) {
      this.privateRecipient = this.convertRecipientType({});
    }
  }

  get isNew() {
    return isEmpty(this.recipient);
  }

  handleRecipientUpdate = ({ detail }) => {
    this.privateRecipient = detail;
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

    switch(this.selectedType) {
      case this.Types.LookupRecipient.value:
        return new LookupRecipient(
          null,
          null,
          this.routingOrder,
          {
              authentication,
              note                        
          }
        );
      case this.Types.RelatedRecipient.value:
        return new RelatedRecipient(
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
        default:
          return new Recipient(
            {
                authentication,
                note 
            }, 
            null, 
            this.routingOrder
          );
     }
  } 
}