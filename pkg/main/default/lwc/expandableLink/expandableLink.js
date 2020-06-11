import { LightningElement, api } from 'lwc';

export default class ExpandableLink extends LightningElement {

    @api
    iconName;

    @api
    label;

    isVisible = false;

    showContent() {
        this.isVisible = true;
        this.dispatchEvent(
            new CustomEvent(
                'expand'
            )
        )        
    }

    hideContent() {
        this.isVisible = false;
        this.dispatchEvent(
            new CustomEvent(
                'collapse'
            )
        )
    }
}