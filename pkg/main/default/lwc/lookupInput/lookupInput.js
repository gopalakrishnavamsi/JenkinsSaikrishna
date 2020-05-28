import { LightningElement, api } from 'lwc';
const DELAY = 300;

export default class LookupInput extends LightningElement {
  @api label = '';
  @api placeHolder = 'Search..';

  constructor() {
    super();
    this.timeout = null;
  }

  handleChange(event) {
    window.clearTimeout(this.timeout);
    let searchTerm = event.target.value;
    this.timeout = setTimeout(() => {
      this.fireChange(searchTerm);
    }, DELAY);
  }

  fireChange(changedValue) {
    let customChange = new CustomEvent('change', { detail: changedValue });
    this.dispatchEvent(customChange);
  }
}