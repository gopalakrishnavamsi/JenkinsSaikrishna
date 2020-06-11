import {LightningElement, api} from 'lwc';
// Custom labels
import signingOrderDiagram from '@salesforce/label/c.SigningOrderDiagram';
import sender from '@salesforce/label/c.Sender';
import completed from '@salesforce/label/c.Completed';
// Static resource
import SIGNING_ORDER_OUTLINE from '@salesforce/resourceUrl/SigningOrderOutline';

//To Do - will be updating this to a dynamic array based on the data we will receive from recipients component.
const routingGroups =  [
  {'routingOrder': 1,
    'recipients': [
      {
        'index' : 1,
        'name' : 'Monkey D. Luffy',
        'email' :  'monkeydluffy@onepiece.com',
        'initials' : 'ML',
        'customId' : 'ML1' // Initials + Index
      },
      {
        'index' : 2,
        'name' : 'Roronoa Zoro',
        'email' :  'roronoazoro@onepiece.com',
        'initials' : 'RZ',
        'customId' : 'RZ2'
      },
    ],
    'hasAdditionalRecipients' : true,
    'additionalRecipients': [
      {
        'name' : 'Nami',
        'email' : '',
        'initials' : 'NN'
      },
      {
        'name' : 'Usopp',
        'email' : '',
        'initials' : 'UU'
      }
    ],
    'numberOfAdditionalRecipients' : 2,
    'routingOrderString' : 'r1'
  },
  {'routingOrder': 2,
    'recipients': [
      {
        'index' : 1,
        'name' : 'Vinsmoke Sanji',
        'email' : '',
        'initials' : 'VS',
        'customId' : 'VS1'
      },
      {
        'index' : 2,
        'name' : 'Tony Tony Chopper',
        'email' : '',
        'initials' : 'TT',
        'customId' : 'TT2'
      }],
    'hasAdditionalRecipients' : true,
    'additionalRecipients': [
      {
        'name' : 'Nico Robin',
        'email' : '',
        'initials' : 'NR'
      },
      {
        'name' : 'Franky',
        'email' : '',
        'initials' : 'FF'
      }
    ],
    'numberOfAdditionalRecipients' : 2,
    'routingOrderString' : 'r2'
  },
  {'routingOrder': 3,
    'recipients': [
      {
        'index' : 1,
        'name' : 'Brook',
        'email' : '',
        'initials' : 'BB',
        'customId' : 'BB1'
      }],
    'hasAdditionalRecipients' : false,
    'additionalRecipients': [],
    'routingOrderString' : 'r3'
  }
];

export default class SigningOrderDiagram extends LightningElement {
  label = {
    signingOrderDiagram,
    sender,
    completed
  };
  showSigningOrderDiagram = false;
  signingOrderOutlineURL = `${SIGNING_ORDER_OUTLINE}#signingOrder`;
  isAdditionalRecipientToolTipVisible = false;
  toolTipLabel = [];

  get orderedRoutingGroups() {
    return routingGroups;
  }

  @api
  handleShow() {
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
    this.toolTipLabel = [ {
      'name' : recipientName ,
      'email' : recipientEmail,
      'iconname' : recipientIconName} ];
    this.template.querySelector('div[data-customid=' + recipientCustomId + ']').style = 'display: block';
  }

  hideRecipientToolTip(event) {
    let recipientCustomId = event.target.dataset.customid;
    this.template.querySelector('div[data-customid=' + recipientCustomId + ']').style = 'display: none';
  }

  handleAdditionalRecipientToolTip(event) {
    let group = event.target.dataset.group;
    let additionalRecipients = routingGroups[group-1].additionalRecipients;
    let i;
    let label = [];
    for (i = 0; i < additionalRecipients.length; i++) {
      label.push(
        {
          'name' : additionalRecipients[i].name,
          'email' : additionalRecipients[i].email,
          'iconname' : additionalRecipients[i].iconName});
    }
    this.toolTipLabel = label;
    let groupString = event.target.dataset.groupstring;
    this.template.querySelector('div[data-customgroupid=' + groupString + ']').style = 'display: block';
  }

  hideAdditionalRecipientToolTip(event) {
    let groupString = event.target.dataset.groupstring;
    this.template.querySelector('div[data-customgroupid=' + groupString + ']').style = 'display: none';
  }
}