/*
 *  Generic progress bar component. Expected attributes:
 *    currentStep : String, expected value - '1','2','3','4'..
 *    steps : Array, {label : '' , value : ''}
 */
import {LightningElement, api} from 'lwc';

export default class ProgressBar extends LightningElement {
  @api disableSteps = false;
  progressSteps = [];

  @api
  get currentStep() {
    return this._currentStep;
  }

  set currentStep(step) {
    this._currentStep = step;
    this.progressSteps = this.updateStepVisuals(this.progressSteps);
  }

  @api
  get steps() {
    return this.progressSteps;
  }

  set steps(val) {
    this.progressSteps = this.updateStepVisuals(val);
  }

  get progressIndicatorStyle() {
    return this.disableSteps ? 'ds-disabled-path' : '';
  }

  handleStep(event) {
    const toStep = event.currentTarget.dataset.step;
    if (toStep === this._currentStep || this.disableSteps) return;
    this.progressSteps = this.updateStepVisuals(this.progressSteps, toStep);
    const progressStepEvent = new CustomEvent('clickprogressstep', {
      detail: {data: toStep}
    });
    this.dispatchEvent(progressStepEvent);
  }

  updateStepVisuals(steps, toStep = this._currentStep) {
    const numericalToStep = parseInt(toStep, 10);
    return steps.map((s) => {
      let style = '';
      const stepNumber = parseInt(s.value, 10);
      if (stepNumber === numericalToStep) {
        style = 'slds-path__item slds-is-current slds-is-active';
      } else if (stepNumber < numericalToStep) {
        style = 'slds-path__item slds-is-complete';
      } else {
        style = 'slds-path__item slds-is-incomplete';
      }
      return {
        ... s,
        style
      };
    });
  }
}