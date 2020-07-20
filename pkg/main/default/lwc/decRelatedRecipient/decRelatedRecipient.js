import {LightningElement, api} from 'lwc';
import {Labels} from 'c/recipientUtils';
import {Filter, OrderByQueriesOptions, Labels as QueryLabels} from 'c/queryUtils';
import {isEmpty} from 'c/utils';

export default class DecRelatedRecipient extends LightningElement {
  Labels = {
    ...Labels,
    ...QueryLabels
  };

  @api
  sourceObject = 'Opportunity';

  @api
  relationship;

  privateFilter;

  isLogicModalOpen = false;

  orderByType;

  @api role;

  @api
  get filter() {
    return this.privateFilter;
  }

  set filter(val) {
    this.privateFilter = isEmpty(val) ? new Filter(null, OrderByQueriesOptions.MostRecent.query) : val;
    this.orderByType = this.privateFilter.orderByType;
  }

  get showFilterPill() {
    return this.privateFilter && !isEmpty(this.privateFilter.filterBy);
  }

  get relatedObject() {
    return this.relationship ? this.relationship.relatesTo : 'Contact';
  }

  get orderByOptions() {
    return Object.values(OrderByQueriesOptions);
  }

  get isCustomOrderBy() {
    return this.orderByType === OrderByQueriesOptions.Custom.value;
  }

  openLogicModal = () => {
    this.isLogicModalOpen = true;
  }

  handleRoleChange({ target }) {
    const value = target.value;
    this.dispatchEvent(new CustomEvent(
      'rolechange',
      {
        detail: { 
          name: 'roleName', 
          value
        } 
      }
    ));
  }

  handleFilterByChange = ({ detail = {}}) => {
    if (!detail) return;
    const { isSave = false, filterBy = null } = detail;
    this.isLogicModalOpen = false;
    if (isSave) {
      this.filter.filterBy = filterBy;
      this.sendFilterChange(this.filter);
    }
  }

  handleFilterPropertyChange = ({ target }) => {
    const { name, value } = target;
    if (name === 'orderBy' || name === 'maximumRecords') this.filter[name] = value;
    else if (name === 'type' && !isEmpty(OrderByQueriesOptions[value])) {
        this.orderByType = value
        this.filter.orderBy = OrderByQueriesOptions[value].query;
        this.sendFilterChange(this.filter);  
    }
    this.sendFilterChange(this.filter);  
  }
  

  removeFilter = () => {
    this.filter = new Filter();
    this.sendFilterChange(this.filter);
  }

  sendFilterChange(filter) {
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
