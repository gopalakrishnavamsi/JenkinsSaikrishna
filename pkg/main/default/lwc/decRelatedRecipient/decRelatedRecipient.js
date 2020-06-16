import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {Filter} from 'c/queryUtils';
import {isEmpty} from 'c/utils';

export default class DecRelatedRecipient extends LightningElement {
  Labels = Labels;

  @api
  sourceObject = 'Opportunity';

  @api
  relationship;

  @api
  get filter() {
    return this.privateFilter;
  }

  set filter(val) {
    this.privateFilter = isEmpty(val) ? new Filter() : val;
  }

  privateFilter;

  isLogicModalOpen = false;

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
      this.filter.filterBy = filterBy;
      this.handleFilterChange(this.filter);
    }
  }

  removeFilter = () => {
    this.filter = new Filter();
    this.handleFilterChange(this.filter);
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

  handleRelationshipSelect = ({ detail }) => {
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