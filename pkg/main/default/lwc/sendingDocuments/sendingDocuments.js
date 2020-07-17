import { LightningElement, api } from 'lwc';

export default class SendingDocuments extends LightningElement {
    @api recordId;
    @api envelopeId;
    @api documents;
    @api forbidEnvelopeChanges;
}