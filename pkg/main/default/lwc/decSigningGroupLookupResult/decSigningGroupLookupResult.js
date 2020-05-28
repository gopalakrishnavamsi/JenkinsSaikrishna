import { LightningElement, api } from 'lwc';

export default class RelationshipLookupResult extends LightningElement {
    @api 
    signingGroup;

    @api
    index;

    handleOnClick() {
        this.dispatchEvent(
            new CustomEvent('selection', { 
                    detail: this.index
            })
        );
    }
}
