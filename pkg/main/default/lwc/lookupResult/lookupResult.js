import {LightningElement, api} from 'lwc';

export default class LookupResult extends LightningElement {
  @api record;

  handleOnClick() {
    let payload = {detail: this.record};
    let selection = new CustomEvent('selection', payload);
    this.dispatchEvent(selection);
  }

  get iconName() {
    return 'standard:' + this.record.objType.toLowerCase();
  }
}
