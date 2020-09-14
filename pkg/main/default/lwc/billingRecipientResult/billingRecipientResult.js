//importing API to expose a public property.
import { LightningElement, api } from 'lwc';

export default class BillingRecipientResult extends LightningElement {
    @api 
    getRecipientLabel;

    @api
    index;

    //send selected recipient to parent cmp after field selection
    handleOnClick() {
        this.dispatchEvent(
            new CustomEvent('selection', {
                    detail: this.index
            })
        );
    }
}