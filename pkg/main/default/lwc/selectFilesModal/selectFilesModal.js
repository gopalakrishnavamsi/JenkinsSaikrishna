import {LightningElement, api} from 'lwc';

//Custom labels
import {LABEL} from 'c/selectFilesModalUtils';
//Apex methods
import getDocumentsOwnedByUser from '@salesforce/apex/FileController.getFilesOwnedByUser';
import getDocumentsSharedWithUser from '@salesforce/apex/FileController.getFilesSharedWithUser';
import getDocumentsRecentlyViewedByUser from '@salesforce/apex/FileController.getFilesRecentlyViewedByUser';
import getDocumentsFollowedByUser from '@salesforce/apex/FileController.getFilesFollowedByUser';
import getContentWorkspaces from '@salesforce/apex/FileController.getContentWorkspaces';
import getContentDocumentsInWorkspace from '@salesforce/apex/FileController.getContentDocumentsInWorkspace';
import linkContentDocuments from '@salesforce/apex/FileController.linkContentDocuments';
//Publisher
import ERROR from '@salesforce/messageChannel/Error__c';
// Lightning message service
import {
  createMessageContext,
  releaseMessageContext
} from 'lightning/messageService';
// utility functions
import {
  genericEvent,
  isEmpty,
  showError,
  spliceArray,
  formatLabels
} from 'c/utils';

const Types = {
  OwnedByMe: {
    value: LABEL.ownedByMe,
    label: LABEL.ownedByMe
  },
  SharedWithMe: {
    value: LABEL.sharedWithMe,
    label: LABEL.sharedWithMe
  },
  Recent: {
    value: LABEL.recent,
    label: LABEL.recent
  },
  Following: {
    value: LABEL.following,
    label: LABEL.following
  },
  Libraries: {
    value: LABEL.libraries,
    label: LABEL.libraries
  }
};

const NUMBER_OF_ROWS = 5;

export default class SelectFilesModal extends LightningElement {
  @api
  soureRecordId;
  searchDocumentsInput;
  label = LABEL;
  types = Types;
  showSelectFiles = false;
  selectedType = this.types.OwnedByMe.value;
  documentsOwnedByUser = [];
  documentsOwnedByUserFiltered = [];
  documentsSharedWithUser = [];
  documentsSharedWithUserFiltered = [];
  documentsRecentlyViewedByUser = [];
  documentsRecentlyViewedByUserFiltered = [];
  documentsFollowedByUser = [];
  documentsFollowedByUserFiltered = [];
  documentsInWorkspace = [];
  documentsInWorkspaceFiltered = [];
  contentWorkspaces = [];
  contentWorkspacesFiltered = [];
  selectedDocuments = [];
  selectedDocumentsSize = 0;
  isContentDocumentInWorkspaceStep = false;
  selectedContentWorkspaceId;
  isEmptyDocs = false;
  isEmptyDocsInWorkspace = false;
  isAddFilesDisabled = true;
  addLabel = this.label.add;
  isSearching = false;
  documentColumns = [
    {
      label: '',
      fieldName: 'Title',
      type: 'selectRow',
      hideDefaultActions: true,
      typeAttributes: {
        rowid: { fieldName : 'Id' },
        extension: { fieldName : 'FileExtension'},
        filesize: { fieldName : 'ContentSize' }
      }
    }];
  contentWorkspaceColumns = [
    {
      label: '',
      fieldName: 'Name',
      type: 'contentWorkspace',
      hideDefaultActions: true,
      typeAttributes: { rowid: { fieldName : 'Id' } }
    }
  ];
  currentOffset = 0;
  totalDocs = 0;
  currentOffsetForDocumentsInWorkspace = 0;
  isLoading = false;
  context = createMessageContext();

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @api
  handleShow() {
    this.showSelectFiles = true;
    this.loadMoreDocumentsOwnedByUser();
  }

  handleClose() {
    this.clearData();
    window.location.reload();
  }

  get selectedOfTotalFilesLabel() {
    return formatLabels(this.label.selectedFilesOfTotalFiles, this.selectedDocumentsSize, this.totalDocs);
  }

  get isDocumentsOwnedByUserStep() {
    return this.selectedType === this.types.OwnedByMe.value;
  }

  get isDocumentsSharedWithUserStep() {
    return this.selectedType === this.types.SharedWithMe.value;
  }

  get isDocumentsRecentlyViewedByUserStep() {
    return this.selectedType === this.types.Recent.value;
  }

  get isDocumentsFollowedByUserStep() {
    return this.selectedType === this.types.Following.value;
  }

  get isContentWorkspacesStep() {
    return this.selectedType === this.types.Libraries.value;
  }

  handleChangeOfSearchInput(event) {
    this.searchDocumentsInput = event.target.value.toLowerCase();
    if(!this.searchDocumentsInput || this.searchDocumentsInput.length < 2) {
      this.isSearching = false;
      return;
    }
    this.isSearching = true;
    let filteredArray = [];
    switch(this.selectedType) {
      case this.types.OwnedByMe.value:
        for (let index = 0; index < this.documentsOwnedByUser.length; index++) {
          if (this.documentsOwnedByUser[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
            filteredArray.push(this.documentsOwnedByUser[index]);
          }
        }
        this.documentsOwnedByUserFiltered = filteredArray;
        break;
      case this.types.SharedWithMe.value:
        for(let index = 0 ; index < this.documentsSharedWithUser.length; index++) {
          if(this.documentsSharedWithUser[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
            filteredArray.push(this.documentsSharedWithUser[index]);
          }
        }
        this.documentsSharedWithUserFiltered = filteredArray;
        break;
      case this.types.Recent.value:
        for(let index = 0 ; index < this.documentsRecentlyViewedByUser.length; index++) {
          if(this.documentsRecentlyViewedByUser[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
            filteredArray.push(this.documentsRecentlyViewedByUser[index]);
          }
        }
        this.documentsRecentlyViewedByUserFiltered = filteredArray;
        break;
      case this.types.Following.value:
        for(let index = 0 ; index < this.documentsFollowedByUser.length; index++) {
          if(this.documentsFollowedByUser[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
            filteredArray.push(this.documentsFollowedByUser[index]);
          }
        }
        this.documentsFollowedByUserFiltered = filteredArray;
        break;
      case this.types.Libraries.value:
        if(!this.isContentDocumentInWorkspaceStep) {
          for (let index = 0; index < this.contentWorkspaces.length; index++) {
            if (this.contentWorkspaces[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
              filteredArray.push(this.contentWorkspaces[index]);
            }
          }
          this.contentWorkspacesFiltered = filteredArray;
        } else {
          for (let index = 0; index < this.documentsInWorkspace.length; index++) {
            if (this.documentsInWorkspace[index].Title.toLowerCase().indexOf(this.searchDocumentsInput) !== -1) {
              filteredArray.push(this.documentsInWorkspace[index]);
            }
          }
          this.documentsInWorkspaceFiltered = filteredArray;
        }
        break;
    }
  }

  handleFileUpload() {
    this.handleClose();
    genericEvent.call(this, 'success', false, false, false);
  }

  loadMoreDocumentsOwnedByUser(event) {
     getDocumentsOwnedByUser({
      offset : this.currentOffset,
      size : NUMBER_OF_ROWS
    })
      .then(data => {
        if (data.length === 0) {
          if (event) {
            event.target.enableInfiniteLoading = false;
          }
          if(this.documentsOwnedByUser.length === 0){
            this.isEmptyDocs = true;
          }
        } else {
          const currentData = this.documentsOwnedByUser;
          const newData = currentData.concat(data);
          this.documentsOwnedByUser = newData;
          this.documentsOwnedByUserClone = this.documentsOwnedByUser;
          this.currentOffset = newData.length;
          this.totalDocs = newData.length;
          this.isEmptyDocs = false;
        }
      })
       .catch(error => showError(this.context, error, ERROR));
  }

  loadMoreDocumentsSharedWithUser(event) {
    getDocumentsSharedWithUser({
      offset : this.currentOffset,
      size : NUMBER_OF_ROWS
    })
      .then(data => {
        if (data.length === 0) {
          if (event) {
            event.target.enableInfiniteLoading = false;
          }
          if(this.documentsSharedWithUser.length === 0){
            this.isEmptyDocs = true;
          }
        }
        else {
          const currentData = this.documentsSharedWithUser;
          const newData = currentData.concat(data);
          this.documentsSharedWithUser = newData;
          this.currentOffset = newData.length;
          this.totalDocs = newData.length;
          this.isEmptyDocs = false;
        }
      })
      .catch(error => showError(this.context, error, ERROR));
  }

  loadDocumentsRecentlyViewedByUser() {
    getDocumentsRecentlyViewedByUser({
      count : NUMBER_OF_ROWS
    })
      .then(data => {
          this.documentsRecentlyViewedByUser = data;
          this.currentOffset = data.length;
          this.totalDocs = data.length;
          this.isEmptyDocs = data.length === 0 ? true : false;
      })
      .catch(error => showError(this.context, error, ERROR));
  }

  loadMoreDocumentsFollowedByUser(event) {
    getDocumentsFollowedByUser({
      offset: this.currentOffset,
      size : NUMBER_OF_ROWS
    })
      .then(data => {
        if (data.length === 0) {
          if (event) {
            event.target.enableInfiniteLoading = false;
          }
          if(this.documentsFollowedByUser.length === 0) {
            this.isEmptyDocs = true;
          }
        }
        else {
          const currentData = this.documentsFollowedByUser;
          const newData = currentData.concat(data);
          this.documentsFollowedByUser = newData;
          this.currentOffset = newData.length;
          this.totalDocs = newData.length;
          this.isEmptyDocs = false;
        }
      })
      .catch(error => showError(this.context, error, ERROR));
  }

  loadMoreContentWorkspaces(event) {
    getContentWorkspaces({
      offset: this.currentOffset,
      size : NUMBER_OF_ROWS
    })
      .then(data => {
        if (data.length === 0) {
          if (event) {
            event.target.enableInfiniteLoading = false;
          }
          if (this.contentWorkspaces.length === 0) {
            this.isEmptyDocs = true;
          }
        }
        else {
          const currentData = this.contentWorkspaces;
          const newData = currentData.concat(data);
          this.contentWorkspaces = newData;
          this.currentOffset = newData.length;
          this.totalDocs = newData.length;
          this.isEmptyDocs = false;
        }
      })
      .catch(error => showError(this.context, error, ERROR));
  }

  loadContentDocumentsInWorkspace(event) {
    this.loadMoreContentDocumentsInWorkspace(event.detail.data, event);
  }

  loadMoreContentDocumentsInWorkspace(contentWorkspaceId, event) {
    let selectedId = contentWorkspaceId;
    if(this.selectedContentWorkspaceId) {
      selectedId = this.selectedContentWorkspaceId;
    } else {
      this.selectedContentWorkspaceId = selectedId;
    }
    this.isContentDocumentInWorkspaceStep = true;
    getContentDocumentsInWorkspace({
      offset : this.currentOffsetForDocumentsInWorkspace,
      size : NUMBER_OF_ROWS,
      contentWorkspaceId : selectedId
    }).then(data => {
      if (data.length === 0) {
        if (this.documentsInWorkspace.length === 0) {
          this.isEmptyDocsInWorkspace = true;
        }
        if (event) {
          event.target.enableInfiniteLoading = false;
        }
      }
      else {
        const currentData = this.documentsInWorkspace;
        const newData = currentData.concat(data);
        this.documentsInWorkspace = newData;
        this.currentOffsetForDocumentsInWorkspace = newData.length;
        this.totalDocs = this.currentOffsetForDocumentsInWorkspace;
        this.isEmptyDocsInWorkspace = false;
      }
    })
      .catch(error => showError(this.context, error, ERROR));
  }

  handleSelectedRow(event) {
    let docId = event.detail.data.rowid;
    let selected = event.detail.data.selected;
    if(selected) {
      this.selectedDocuments.push(docId);
    } else {
      this.selectedDocuments = this.selectedDocuments.filter(d => d !== docId);
    }
    this.selectedDocumentsSize = this.selectedDocuments.length;
    this.isAddFilesDisabled = this.selectedDocumentsSize === 0 ? true : false;
    if(!this.isAddFilesDisabled) {
      this.addLabel = this.label.add + ' (' + this.selectedDocumentsSize + ')';
    }
  }

  clearData() {
    this.currentOffset = 0;
    this.totalDocs = 0;
    this.selectedDocumentsSize = 0;
    this.currentOffsetForDocumentsInWorkspace = 0;
    this.selectedContentWorkspaceId = null;
    this.isContentDocumentInWorkspaceStep = false;
    this.documentsOwnedByUser = [];
    this.documentsSharedWithUser = [];
    this.documentsRecentlyViewedByUser = [];
    this.documentsFollowedByUser = [];
    this.selectedDocuments = [];
    this.contentWorkspaces = [];
    this.documentsInWorkspace = [];
    this.addLabel = this.label.add;
    this.isAddFilesDisabled = true;
    this.isEmptyDocs = false;
    this.isEmptyDocsInWorkspace = false;
    this.isSearching = false;
    this.searchDocumentsInput = '';
  }

  handleTypeChange = ({detail}) => {
    if (this.selectedType === detail.name) return;
    this.clearData();
    this.selectedType = detail.name;
    //todo - can we do without calling service method once all docs are loaded.
    switch (this.selectedType) {
      case this.types.OwnedByMe.value:
        this.loadMoreDocumentsOwnedByUser();
        break;
      case this.types.SharedWithMe.value:
        this.loadMoreDocumentsSharedWithUser();
        break;
      case this.types.Recent.value:
        this.loadDocumentsRecentlyViewedByUser();
        break;
      case this.types.Following.value:
        this.loadMoreDocumentsFollowedByUser();
        break;
      case this.types.Libraries.value:
        this.loadMoreContentWorkspaces();
        break;
    }
  }

  handleAddFiles() {
      this.isLoading = true;
      linkContentDocuments({
        contentDocumentIds : this.selectedDocuments,
        sourceObjectId : this.soureRecordId
      }).then(result => {
        this.isLoading = false;
        if(!isEmpty(result)) {
          let errorMsg =
            {
              body : {
                message : result
              }
            };
          showError(this.context, errorMsg, ERROR);
        } else {
          this.handleClose();
        }
      }).catch(error => {
          showError(this.context, error, ERROR);
          this.isLoading = false;
      });
  }

  handleBackFromContentWorkspace() {
    spliceArray(this.documentsInWorkspace);
    this.selectedContentWorkspaceId = undefined;
    this.isContentDocumentInWorkspaceStep = false;
    this.currentOffsetForDocumentsInWorkspace = 0;
    this.totalDocs = this.currentOffset;
  }
}