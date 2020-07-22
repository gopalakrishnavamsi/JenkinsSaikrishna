/*
 *  Generic progress bar component. Expected attributes:
 *    currentStep : String, expected value - '1','2','3','4'..
 *    steps : Array, {label : '' , value : ''}
 */
import {LightningElement, api} from 'lwc';

export default class ProgressBar extends LightningElement {
  @api disableSteps = false;
  @api currentStep;
  steps;

  get progressIndicatorStyle() {
    return this.disableSteps ? 'ds-disabled-path' : '';
  }

  @api
  progressSteps(value) {
    this.steps = value;
  }

  handleStep(event) {
    if (this.disableSteps) return;
    const progressStepEvent = new CustomEvent('clickprogressstep', {
      detail: {data: event.target.value}
    });
    this.dispatchEvent(progressStepEvent);
  }
}