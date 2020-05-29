import { LightningElement, api } from 'lwc';
import searchPlaceHolder from '@salesforce/label/c.SearchPlaceHolder';
const DELAY = 300;

export default class LookupInput extends LightningElement {
  @api label = '';
  @api placeHolder = searchPlaceHolder;
  @api required = false;

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