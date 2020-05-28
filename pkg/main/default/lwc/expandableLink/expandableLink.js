import { LightningElement, api } from 'lwc';

export default class ExpandableLink extends LightningElement {

    @api
    iconName;

    @api
    label;

    isVisible = false;

    showContent() {
        this.isVisible = true;
    }

    hideContent() {
        this.isVisible = false;
    }
}