import {createElement} from 'lwc';
import ProgressBar from 'c/progressBar';
import {STEPS, PROGRESS_STEP} from 'c/setupUtils';

describe('c-progress-bar', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('Progress bar without tagger is displayed when steps are passed', () => {
    const element = createElement('c-progress-bar', {
      is: ProgressBar
    });
    //setting @api attributes
    element.steps = STEPS;
    element.currentStep = PROGRESS_STEP.DOCUMENTS;
    document.body.appendChild(element);

    const progressBarContainer = element.shadowRoot.querySelector(
      '.slds-path__scroller-container'
    );
    expect(progressBarContainer).not.toBeNull();

    const pathLinks = element.shadowRoot.querySelectorAll(
      '.slds-path__link'
    );
    expect(pathLinks.length).toBe(4);
  });

  it('If Tagger is enabled then it is displayed on UI', () => {
    const element = createElement('c-progress-bar', {
      is: ProgressBar
    });
    //setting @api attributes
    let taggerStepUpdated = STEPS.slice();
    taggerStepUpdated[2].disabled = false;
    element.steps = taggerStepUpdated;
    element.currentStep = PROGRESS_STEP.DOCUMENTS;
    document.body.appendChild(element);
    const pathLinks = element.shadowRoot.querySelectorAll(
      '.slds-path__link'
    );
    expect(pathLinks.length).toBe(5);
  });

  it('Do not dispatch event on click of progress step if the current step is same', () => {
    const handler = jest.fn();
    const element = createElement('c-progress-bar', {
      is: ProgressBar
    });
    //setting @api attributes
    element.steps = STEPS;
    element.currentStep = PROGRESS_STEP.DOCUMENTS;
    element.addEventListener('clickprogressstep', handler);
    document.body.appendChild(element);

    const progressStep = element.shadowRoot.querySelector(
      '.slds-path__link'
    );
    progressStep.dispatchEvent(new CustomEvent('click'));
    return Promise.resolve()
      .then(() => {
        expect(handler).not.toHaveBeenCalled();
      });
  });

  it('Dispatch event on click of progress step if the current step is different', () => {
    const handler = jest.fn();
    const element = createElement('c-progress-bar', {
      is: ProgressBar
    });
    //setting @api attributes
    element.steps = STEPS;
    element.currentStep = PROGRESS_STEP.DOCUMENTS;
    element.addEventListener('clickprogressstep', handler);
    document.body.appendChild(element);
    expect(element.currentStep).toBe(PROGRESS_STEP.DOCUMENTS);
    element.currentStep = PROGRESS_STEP.RECIPIENTS;
    const progressStep = element.shadowRoot.querySelector(
      '.slds-path__link'
    );
    progressStep.dispatchEvent(new CustomEvent('click'));
    return Promise.resolve()
      .then(() => {
        expect(handler).toHaveBeenCalled();
      });
  });
});