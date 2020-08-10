import { LightningElement, api } from 'lwc';
import {getRandomKey} from 'c/utils';

export default class RelationshipLookupResult extends LightningElement {
    @api 
    relationship;

    @api
    index;

    get key() {
        return getRandomKey();
    }

    handleOnClick() {
        this.dispatchEvent(
            new CustomEvent('selection', { 
                    detail: this.index
            })
        );
    }
}
