import { LightningElement, api } from 'lwc';

// utility functions
import { genericEvent } from 'c/utils';
import { LABEL, OPERATION } from 'c/sendingUtils';

// static resources
import sendingIconUrl from '@salesforce/resourceUrl/sendingIcon';

export default class SendingHeader extends LightningElement {
    @api recordId;
    @api isFirstStep;
    @api isFinalStep;
    @api nextStepButtonText;

    label = LABEL;
    sendingIcon = sendingIconUrl;
    showExitModal = false;


    closeExitModal() {
        this.showExitModal = false;
    }

    openExitModal() {
        this.showExitModal = true;
    }

    exitWorkflow() {
        genericEvent.call(this, 'exitworkflow', null, true);
    }

    handleBack() {
        genericEvent.call(this, 'clickprogressstep', OPERATION.BACK, true);
    }

    handleNext() {
        genericEvent.call(this, 'clickprogressstep', OPERATION.NEXT, true);
    }
}