import { LightningElement, api } from 'lwc';

export default class SendingRecipients extends LightningElement {
    @api recipients;
    @api forbidEnvelopeChanges;
}