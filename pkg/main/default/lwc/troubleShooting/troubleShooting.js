import {LightningElement} from 'lwc';
import DocuSignLogo from '@salesforce/resourceUrl/Logo';
import DisconnectedLogo from '@salesforce/resourceUrl/DecAddRecipientsEmpty';
import TroubleShootingTitle from '@salesforce/label/c.TroubleShootingTitle';
import TroubleShootingDisconnectAccount from '@salesforce/label/c.TroubleShootingDisconnectAccount';
import TroubleShootingDisconnectAccountInfo from '@salesforce/label/c.TroubleShootingDisconnectAccountInfo';
import TroubleShootingFolderPermissions from '@salesforce/label/c.TroubleShootingFolderPermissions';
import TroubleShootingFolderPermissionsInfo from '@salesforce/label/c.TroubleShootingFolderPermissionsInfo';
import TroubleShootingConnectedApp from '@salesforce/label/c.TroubleShootingConnectedApp';
import TroubleShootingConnectedAppInfo from '@salesforce/label/c.TroubleShootingConnectedAppInfo';
import TroubleShootingNoAccountConnected from '@salesforce/label/c.TroubleShootingNoAccountConnected';
import TroubleShootingError from '@salesforce/label/c.TroubleShootingError';
import getLoginInformation from '@salesforce/apex/TroubleShootingController.getLoginInformation';
import {isEmpty} from 'c/utils';

export default class TroubleShooting extends LightningElement {
  docuSignLogo = DocuSignLogo;
  disconnectedLogo = DisconnectedLogo;
  isLoading = true;
  showToast = false
  loginInformation = {
    environment: null,
    accountEmail: null,
    accountNumber: null,
    status: 'disconnected'
  };
  loginInformationError = false;
  toastMessage;
  toastMode;
  troubleShootingTitle = TroubleShootingTitle;
  troubleShootingDisconnectAccount = TroubleShootingDisconnectAccount;
  troubleShootingDisconnectAccountInfo = TroubleShootingDisconnectAccountInfo;
  troubleShootingFolderPermissions = TroubleShootingFolderPermissions;
  troubleShootingFolderPermissionsInfo = TroubleShootingFolderPermissionsInfo;
  troubleShootingConnectedApp = TroubleShootingConnectedApp;
  troubleShootingConnectedAppInfo = TroubleShootingConnectedAppInfo;
  troubleShootingNoAccountConnected = TroubleShootingNoAccountConnected;
  troubleShootingError = TroubleShootingError;

  connectedCallback() {
    getLoginInformation()
      .then(res => {
        this.loginInformation = res;
        this.isLoading = false;
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
        this.loginInformationError = true;
      });
  }

  get isDocuSignAccountConnected() {
    return !isEmpty(this.loginInformation)
      & !isEmpty(this.loginInformation.status)
      & this.loginInformation.status === 'connected'
      & this.loginInformationError === false;
  }

  get isDocuSignAccountDisconnected() {
    return !isEmpty(this.loginInformation)
      & !isEmpty(this.loginInformation.status)
      & this.loginInformation.status === 'disconnected'
      & this.loginInformationError === false;
  }

}