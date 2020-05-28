import { LightningElement, api } from 'lwc';
//labels
import fileSizeLimitReached from '@salesforce/label/c.FileSizeLimitReached_2';
import uploadFile from '@salesforce/label/c.UploadFile';
// utility functions
import {ERROR_EVENT_LABEL, SUCCESS_EVENT_LABEL, formatFileSize, genericEvent, } from 'c/utils';
//apex methods
import saveChunk from '@salesforce/apex/FileController.saveChunk';

const MAX_FILE_SIZE = 4718592; // 4.5 MB
const CHUNK_SIZE = 768000; // 750 KB
const BASE_64_PREFIX = 'base64,';
const MAX_PROGRESS = 100;

export default class FileUpload extends LightningElement {
  @api recordId;
  @api fileUploadLabel;
  label = {
    fileSizeLimitReached,
    uploadFile
  };
  progress = 0;
  showUploadFilesModal = false;
  fileName = '';
  file;
  fileContents;
  fileReader;
  extension = '';

  get progressWidth() {
    return `width: ${this.progress}%`;
  }

  get fileSize() {
    return this.file ? formatFileSize(this.file.size, 0) : 0;
  }

  get isFileUploadedSuccessful() {
    return this.progress === MAX_PROGRESS ? true : false;
  }

  closeUploadFilesModal() {
    this.showUploadFilesModal = false;
    this.progress = 0;
  }

  handleFilesChange(event) {
    if(event.target.files.length > 0) {
      this.file = event.target.files[0];
      this.fileName = event.target.files[0].name;
      if (this.file.size > MAX_FILE_SIZE) {
        genericEvent(ERROR_EVENT_LABEL,this.label.fileSizeLimitReached,this,false);
        return;
      }
      this.extension = this.file.name.split('.').pop();
      this.showUploadFilesModal = true;
      this.fileReader= new FileReader();
      this.fileReader.onloadend = (() => {
        this.fileContents = this.fileReader.result;
        this.fileContents = this.fileContents.substring(this.fileContents.indexOf(BASE_64_PREFIX) + BASE_64_PREFIX.length);
        this.setProgressBar();
        this.saveFile();
      });
      this.fileReader.readAsDataURL(this.file);
    }
  }

  setProgressBar() {
    let intervalID = setInterval(function (){
      if (this.progress === MAX_PROGRESS) {
        clearInterval(intervalID);
      } else {
        this.progress++;
      }
    }.bind(this),10);
  }

  saveFile() {
    let start = 0;
    let end = Math.min(this.fileContents.length, CHUNK_SIZE);
    saveChunk({
      contentVersionId: null,
      linkedEntityId: this.recordId,
      fileName: this.file.name,
      base64Data: encodeURIComponent(this.fileContents.substring(start, end))})
      .then(result => {
        this.progress = MAX_PROGRESS;
        genericEvent(SUCCESS_EVENT_LABEL, result, this, false);
      })
      .catch(error => {
        if (error.body !== null) {
          genericEvent(ERROR_EVENT_LABEL, error.body.message, this, false);
        }
      });
  }

}