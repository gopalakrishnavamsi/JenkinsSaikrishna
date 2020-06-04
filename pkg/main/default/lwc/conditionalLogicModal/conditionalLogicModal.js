import {LightningElement,api} from 'lwc';
import {isEmpty} from 'c/utils';
import saveLabel from '@salesforce/label/c.Save';
import cancelLabel from '@salesforce/label/c.Cancel';
import addFilterLabel from '@salesforce/label/c.AddFilterLabel';

export default class ConditionalLogicModal extends LightningElement {
    @api
    isOpen;

    @api
    filter;

    logic;

    @api
    sourceObject;

    Labels = {
        saveLabel,
        cancelLabel,
        addFilterLabel
    }

    connectedCallback() {
        if(isEmpty(this.logic) && !isEmpty(this.filter)) {
            this.filter.getConditionalLogic()
            .then(res => {
                if (!res.hasRules) res.addRule();
                this.logic = res;
            })
            .catch(err => this.dispatchEvent(
                new CustomEvent(
                    'error', 
                    {
                        detail: err
                    }
                
                )
            ));
        } 
    }

    handleUpdate = ({ detail }) => {
        this.logic = detail;
    }

    handleClose = () => {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                isSave: false            
            }
        }))        
    }

    handleSave = () => {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                isSave: true,
                filterBy: this.logic.toString()
            }
        }))
    }
}