import {LightningElement, api} from 'lwc';
import HelpVideoImage from '@salesforce/resourceUrl/HelpVideoImage';

export default class HelpVideoImageBox extends LightningElement {
  helpVideoImage = HelpVideoImage;

  @api
  videoText;

  @api
  videoLength;

  @api
  videoLink;

}