import {LightningElement, api} from 'lwc';
// Custom labels
import signingOrderDiagram from '@salesforce/label/c.SigningOrderDiagram';
import sender from '@salesforce/label/c.Sender';
import completed from '@salesforce/label/c.Completed';
// Static resource
import SIGNING_ORDER_OUTLINE from '@salesforce/resourceUrl/SigningOrderOutline';
import {isEmpty, groupBy} from 'c/utils';
import {RecipientGroupedByRoutingOrder} from 'c/recipientUtils';

export default class SigningOrderDiagram extends LightningElement {

  @api
  recipients = [];

  label = {
    signingOrderDiagram,
    sender,
    completed
  };
  showSigningOrderDiagram = false;
  signingOrderOutlineURL = `${SIGNING_ORDER_OUTLINE}#signingOrder`;
  isAdditionalRecipientToolTipVisible = false;
  toolTipLabel = [];

  orderedRoutingGroups = [];

  @api
  handleShow() {

    this.orderedRoutingGroups = [];
    let recipientsGroup = groupBy(this.recipients, 'routingOrder');
    for (let key of Object.keys(recipientsGroup)) {
      this.orderedRoutingGroups.push(new RecipientGroupedByRoutingOrder(key, recipientsGroup[key]));
    }
    this.showSigningOrderDiagram = true;
  }

  handleClose() {
    this.showSigningOrderDiagram = false;
  }

  get signingOrderImage() {
    return `background-image: url(${this.signingOrderOutlineURL})`;
  }

  handleRecipientToolTip(event) {
    let recipientName = event.target.dataset.name;
    let recipientEmail = event.target.dataset.email;
    let recipientIconName = event.target.dataset.iconname;
    let recipientCustomId = event.target.dataset.customid;
    this.toolTipLabel = [{
      'id': recipientCustomId,
      'name': recipientName,
      'email': recipientEmail,
      'iconname': recipientIconName
    }];
    if (!isEmpty(recipientCustomId)) {
      this.template.querySelector('div[data-customid=' + recipientCustomId + ']').style = 'display: block';
    }
  }

  hideRecipientToolTip(event) {
    let recipientCustomId = event.target.dataset.customid;
    if (!isEmpty(recipientCustomId)) {
      this.template.querySelector('div[data-customid=' + recipientCustomId + ']').style = 'display: none';
    }
  }

  handleAdditionalRecipientToolTip(event) {
    let group = event.target.dataset.group;
    let additionalRecipients = this.orderedRoutingGroups[group - 1].additionalRecipients;
    let i;
    let label = [];
    let groupString = event.target.dataset.groupstring;
    for (i = 0; i < additionalRecipients.length; i++) {
      label.push(
        {
          'id': 'additional-' + groupString + '-' + i,
          'name': !isEmpty(additionalRecipients[i].name) ? additionalRecipients[i].name : ' ',
          'email': additionalRecipients[i].email,
          'iconname': additionalRecipients[i].iconName
        });
    }
    this.toolTipLabel = label;
    if (!isEmpty(groupString)) {
      this.template.querySelector('div[data-customgroupid=' + groupString + ']').style = 'display: block';
    }
  }

  hideAdditionalRecipientToolTip(event) {
    let groupString = event.target.dataset.groupstring;
    if (!isEmpty(groupString)) {
      this.template.querySelector('div[data-customgroupid=' + groupString + ']').style = 'display: none';
    }
  }
}