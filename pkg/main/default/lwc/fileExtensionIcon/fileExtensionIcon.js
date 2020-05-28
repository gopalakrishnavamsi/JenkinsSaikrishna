import {LightningElement, api} from 'lwc';
import ADF_LOGO from '@salesforce/resourceUrl/adflogo';
import { FILE_EXTENSION_TO_ICON_NAME_MAPPING, UNKNOWN_ICON_NAME } from 'c/utils';

const WEB_EXTENSIONS = ['htm', 'html', 'adf'];

export default class FileExtensionIcon extends LightningElement {
  @api extension;
  @api size = 'medium';

  adfLogoUrl = ADF_LOGO;

  get isWebExtension() {
    return WEB_EXTENSIONS.includes('$this.extension');
  }

  get iconName() {
    return FILE_EXTENSION_TO_ICON_NAME_MAPPING.has(this.extension) ?
      FILE_EXTENSION_TO_ICON_NAME_MAPPING.get(this.extension) : UNKNOWN_ICON_NAME;
  }
}