/*
 *  Generic progress bar component. Expected attributes:
 *    currentStep : String, expected value - '1','2','3','4'..
 *    steps : Array, {label : '' , value : ''}
 */
import {LightningElement, api} from 'lwc';

export default class ProgressBar extends LightningElement {
  @api currentStep;
  @api steps;

  handleStep(event) {
    const progressStepEvent = new CustomEvent('clickprogressstep', {
      detail: {data : event.target.value}
    });
    this.dispatchEvent(progressStepEvent);
  }
}