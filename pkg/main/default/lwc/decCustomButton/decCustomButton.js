import {LightningElement, api, wire} from 'lwc';

//Apex
import getLayouts from '@salesforce/apex/MetadataController.getLayouts';
import updateLayouts from '@salesforce/apex/MetadataController.updateLayouts';
import getDecActionName from '@salesforce/apex/MetadataController.getDecActionName';

// Lightning message service
import {
  createMessageContext,
  releaseMessageContext
} from 'lightning/messageService';

// utility functions
import {
  showError,
  showSuccess,
  subscribeToMessageChannel
} from 'c/utils';
import {LABEL} from 'c/customButtonUtils';

// Publisher
import DEC_ERROR from '@salesforce/messageChannel/DecError__c';
import DEC_SUCCESS from '@salesforce/messageChannel/DecSuccess__c';

// Subscriber
import DEC_UPDATE_PAGE_LAYOUTS from '@salesforce/messageChannel/DecUpdatePageLayouts__c';

const DEC = 'DEC';

export default class DecCustomButton extends LightningElement {
  @api recordId;
  @api sourceObject;
  isLoading = true;
  layouts;
  selectedPageLayouts = [];
  decButtonLabel = '';
  decButtonApiName = '';
  context = createMessageContext();
  label = LABEL;
  pageLayoutColumns = [
    {
      label: 'Page Layouts',
      fieldName: 'name',
      type: 'text',
      hideDefaultActions: true
    }];

  //Subscriptions
  updatePageLayoutsSubscription = null;

  connectedCallback() {
    this.updatePageLayoutsSubscription = subscribeToMessageChannel(
      this.context,
      this.updatePageLayoutsSubscription,
      DEC_UPDATE_PAGE_LAYOUTS,
      this.handleUpdateLayouts.bind(this)
    );
  }

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @wire(getLayouts, {
    sObjectType: '$sourceObject'
  })
  getLayouts({error, data}) {
    if (error) {
      showError(this.context, error, DEC_ERROR);
    } else if (data) {
      this.parseLayouts(data);
      this.isLoading = false;
    }
  }

  @wire(getDecActionName, {
    sObjectType: '$sourceObject'
  })
  getDecActionName({error, data}) {
    if (error) {
      showError(this.context, error, DEC_ERROR);
    } else if (data) {
      this.decButtonApiName = data + this.recordId;
    }
  }

  setLoading(isTrue) {
    this.isLoading = isTrue ? true : false;
  }

  parseLayouts(result) {
    this.layouts = this.processLayouts(result.map(d => JSON.parse(JSON.stringify(d))));
    this.selectedPageLayouts = [];
    for (let i = 0; i < this.layouts.length; i++) {
      if (this.layouts[i].hasDecAction === true) {
        this.selectedPageLayouts.push(this.layouts[i].id);
      }
    }
  }

  processLayouts(data) {
    let result = [];
    for (let i = 0; i < data.length; i++) {
      let layout = data[i];
      layout.hasDecAction =
        layout.hasOwnProperty('hasDecAction') ? layout.hasDecAction : this.hasDecAction(layout, true);
      layout.original = this.copyLayout(layout);
      result.push(layout);
    }
    return result;
  }

  hasDecAction(layout, update) {
    for (let i = 0; i < layout.actions.length; i++) {
      let action = layout.actions[i];
      if (action.type === DEC && action.name === this.decButtonApiName) {
        if (update) {
          this.decButtonLabel = action.label;
        }
        return true;
      }
    }
    return false;
  }

  handleButtonLabelChange(event) {
    this.decButtonLabel = event.target.value;
  }

  isLabelUpdated(layout) {
    let originalLabel;
    for (let i = 0; i < layout.original.actions.length; i++) {
      let originalAction = layout.original.actions[i];
      if (originalAction.type === DEC && originalAction.name === this.decButtonApiName) {
        originalLabel = originalAction.label;
        break;
      }
    }
    return !!(originalLabel !== this.decButtonLabel && layout.hasDecAction);
  }

  isLayoutDirty(layout) {
    layout.hasDecAction = false;
    let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows().slice();
    for (let i = 0; i < selectedRows.length; i++) {
      if (layout.id === selectedRows[i].id) {
        layout.hasDecAction = true;
      }
    }
    return (layout.hasDecAction !== layout.original.hasDecAction || this.isLabelUpdated(layout));
  }

  copyLayout(layout) {
    let result = null;
    result = JSON.parse(JSON.stringify(layout));
    delete result.original;
    return result;
  }

  getLayoutsToUpdate(layouts, decActionName) {
    let ls = [];
    for (let i = 0; i < layouts.length; i++) {
      if (!this.isLayoutDirty(layouts[i])) continue;
      let layout = this.copyLayout(layouts[i]);
      layout.actions = [];
      if (layout.hasDecAction) {
        layout.actions.push({
          type: DEC, name: decActionName, label: this.decButtonLabel
        });
      }

      delete layout.hasDecAction;
      delete layout.original;
      ls.push(layout);
    }
    return ls;
  }

  handleUpdateLayouts() {
    this.setLoading(true);
    let parameters = {
      decButtonApiName: this.decButtonApiName,
      decButtonLabel: this.decButtonLabel,
      decTemplateId: this.recordId
    };
    let selectedLayouts = this.getLayoutsToUpdate(this.layouts, this.decButtonApiName);
    updateLayouts({
      sObjectType: this.sourceObject,
      layoutsJson: JSON.stringify(selectedLayouts),
      parameters: JSON.stringify(parameters)
    })
      .then(() => {
        showSuccess(this.context, this.label.successfullyModifiedLayouts, DEC_SUCCESS);
        this.setLoading(false);
      })
      .catch(error => {
        showError(this.context, error, DEC_ERROR);
        this.setLoading(false);
      });
  }
}