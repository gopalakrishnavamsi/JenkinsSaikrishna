import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {Filter} from 'c/queryUtils';
import { isEmpty } from 'c/utils';



export default class DecRelatedRecipient extends LightningElement {
  Labels = Labels;

  @api
  sourceObject = 'Opportunity';

  @api
  relationship;

  @api
  filter;

  privateFilter;

  isLogicModalOpen = false;

  connectedCallback() {
    if (!isEmpty(this.filter) && isEmpty(this.privateFilter)) {
      this.privateFilter = this.filter;
    } else if (isEmpty(this.privateFilter)) {
      this.privateFilter = new Filter();  
    }
  }

  get showFilterPill() {
    return this.privateFilter && !this.privateFilter.isEmpty;
  }

  get relatedObject() {
    return this.relationship ? this.relationship.relatesTo : 'Contact';
  }

  openLogicModal = () => {
    this.isLogicModalOpen = true;
  }

  handleFilterByChange = ({ detail = {}}) => {
    if (!detail) return;
    const { isSave = false, filterBy = null } = detail;
    this.isLogicModalOpen = false;
    if (isSave) {
      this.privateFilter.filterBy = filterBy;
      this.handleFilterChange(this.privateFilter);
    }
  }

  removeFilter = () => {
    this.privateFilter = new Filter();
    this.handleFilterChange(this.privateFilter);
  }

  handleFilterChange(filter) {
    this.dispatchEvent(
      new CustomEvent(
        'filterchange',
        {
          detail: filter
        }
      )
    )
  }

  handleSelect({ detail }) {
    this.relationship = detail;
    this.dispatchEvent(
      new CustomEvent(
        'relationshipupdate',
        {
            detail 
        }
      )
    );
  }
}