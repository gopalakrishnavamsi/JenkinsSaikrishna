import { LightningElement, api } from 'lwc';

export default class ExpandableLink extends LightningElement {

    @api
    iconName;

    @api
    label;

    @api
    forbidChanges = false;

    isOpen = false;

    @api
    get isVisible() {
        return this.isOpen;
    }

    set isVisible(val) {
        this.isOpen = val;
    }

    showContent = () => {
        this.isVisible = true;
        this.dispatchEvent(
            new CustomEvent(
                'expand'
            )
        )        
    }

    hideContent = () => {
        this.isVisible = false;
        this.dispatchEvent(
            new CustomEvent(
                'collapse'
            )
        )
    }
}