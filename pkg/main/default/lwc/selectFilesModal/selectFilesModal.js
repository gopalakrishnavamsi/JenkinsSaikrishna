import {LightningElement, api, wire} from 'lwc';

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
  showError,
  spliceArray
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
  documentsSharedWithUser = [];
  documentsRecentlyViewedByUser = [];
  documentsFollowedByUser = [];
  documentsInWorkspace = [];
  contentWorkspaces = [];
  selectedDocuments = [];
  isContentDocumentInWorkspaceStep = false;
  selectedContentWorkspaceId;
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
  currentOffset;
  currentOffsetForDocumentsInWorkspace = 0;
  isLoading = false;
  context = createMessageContext();

  disconnectedCallback() {
    releaseMessageContext(this.context);
  }

  @api
  handleShow() {
    this.showSelectFiles = true;
  }

  handleClose() {
    this.showSelectFiles = false;
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

  @wire(getDocumentsOwnedByUser, {
    offset : 0,
    size: NUMBER_OF_ROWS})
  getDocumentsOwnedByUser({error, data}) {
    if (error) {
      showError(this.context, error, ERROR);
    } else if (data) {
      this.documentsOwnedByUser = data;
      this.currentOffset = data.length;
    }
  }

  handleChangeOfSearchInput(event) {
    this.searchDocumentsInput = event.target.value;
    //todo filter array...
  }

  handleFileUpload() {
    this.handleClose();
    window.location.reload();
    genericEvent.call(this, 'success', false, false, false);
  }

  loadMoreDocumentsOwnedByUser(event) {
     getDocumentsOwnedByUser({
      offset : this.currentOffset,
      size : NUMBER_OF_ROWS
    })
      .then(data => {
        if (data.length === 0) {
          event.target.enableInfiniteLoading = false;
        } else {
          const currentData = this.documentsOwnedByUser;
          const newData = currentData.concat(data);
          this.documentsOwnedByUser = newData;
          this.documentsOwnedByUserClone = this.documentsOwnedByUser;
          this.currentOffset = newData.length;
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
          event.target.enableInfiniteLoading = false;
        }
        else {
          const currentData = this.documentsSharedWithUser;
          const newData = currentData.concat(data);
          this.documentsSharedWithUser = newData;
          this.currentOffset = newData.length;
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
          event.target.enableInfiniteLoading = false;
        }
        else {
          const currentData = this.documentsFollowedByUser;
          const newData = currentData.concat(data);
          this.documentsFollowedByUser = newData;
          this.currentOffset = newData.length;
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
          event.target.enableInfiniteLoading = false;
        }
        else {
          const currentData = this.contentWorkspaces;
          const newData = currentData.concat(data);
          this.contentWorkspaces = newData;
          this.currentOffset = newData.length;
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
        event.target.enableInfiniteLoading = false;
      }
      else {
        const currentData = this.documentsInWorkspace;
        const newData = currentData.concat(data);
        this.documentsInWorkspace = newData;
        this.currentOffsetForDocumentsInWorkspace = newData.length;
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
  }

  handleTypeChange = ({detail}) => {
    this.currentOffset = 0;
    this.currentOffsetForDocumentsInWorkspace = 0;
    this.selectedContentWorkspaceId = null;
    this.isContentDocumentInWorkspaceStep = false;

    if (this.selectedType === detail.name) return;
    this.selectedType = detail.name;

    spliceArray(this.selectedDocuments);
    //todo - can we do without calling service method once all docs are loaded.
    switch (this.selectedType) {
      case this.types.OwnedByMe.value:
        spliceArray(this.documentsOwnedByUser);
        this.loadMoreDocumentsOwnedByUser();
        break;
      case this.types.SharedWithMe.value:
        spliceArray(this.documentsSharedWithUser);
        this.loadMoreDocumentsSharedWithUser();
        break;
      case this.types.Recent.value:
        spliceArray(this.documentsRecentlyViewedByUser);
        this.loadDocumentsRecentlyViewedByUser();
        break;
      case this.types.Following.value:
        spliceArray(this.documentsFollowedByUser);
        this.loadMoreDocumentsFollowedByUser();
        break;
      case this.types.Libraries.value:
        spliceArray(this.contentWorkspaces);
        spliceArray(this.documentsInWorkspace);
        this.loadMoreContentWorkspaces();
        break;
    }
  }

  handleAddFiles() {
      this.isLoading = true;
      linkContentDocuments({
        contentDocumentIds : this.selectedDocuments,
        sourceObjectId : this.soureRecordId
      }).then(() => {
        this.isLoading = false;
        this.handleClose();
        //todo..do not reload entire window?
        window.location.reload();
      })
        .catch(error => {
          showError(this.context, error, ERROR);
          this.isLoading = false;
        });
  }

  handleBackFromContentWorkspace() {
    spliceArray(this.documentsInWorkspace);
    this.selectedContentWorkspaceId = undefined;
    this.isContentDocumentInWorkspaceStep = false;
    this.currentOffsetForDocumentsInWorkspace = 0;
  }
}