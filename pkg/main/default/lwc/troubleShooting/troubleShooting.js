import {LightningElement} from 'lwc';
import DocuSignLogo from '@salesforce/resourceUrl/Logo';
import DisconnectedLogo from '@salesforce/resourceUrl/DecAddRecipientsEmpty';
import TroubleShootingTitle from '@salesforce/label/c.TroubleShootingTitle';
import TroubleShootingDisconnectAccount from '@salesforce/label/c.TroubleShootingDisconnectAccount';
import TroubleShootingDisconnectAccountInfo from '@salesforce/label/c.TroubleShootingDisconnectAccountInfo';
import TroubleShootingDisconnectAccountResetUsers from '@salesforce/label/c.TroubleShootingDisconnectAccountResetUsers';
import TroubleShootingDisconnectAccountResetUsersInfo from '@salesforce/label/c.TroubleShootingDisconnectAccountResetUsersInfo';
import TroubleShootingFolderPermissions from '@salesforce/label/c.TroubleShootingFolderPermissions';
import TroubleShootingFolderPermissionsInfo from '@salesforce/label/c.TroubleShootingFolderPermissionsInfo';
import TroubleShootingConnectedApp from '@salesforce/label/c.TroubleShootingConnectedApp';
import TroubleShootingConnectedAppInfo from '@salesforce/label/c.TroubleShootingConnectedAppInfo';
import TroubleShootingConnectedAppRemovePermissions from '@salesforce/label/c.TroubleShootingConnectedAppRemovePermissions';
import TroubleShootingConnectedAppRemovePermissionsInfo from '@salesforce/label/c.TroubleShootingConnectedAppRemovePermissionsInfo';
import TroubleShootingNoAccountConnected from '@salesforce/label/c.TroubleShootingNoAccountConnected';
import TroubleShootingError from '@salesforce/label/c.TroubleShootingError';
import TroubleShootingLogoutSuccess from '@salesforce/label/c.TroubleShootingLogoutSuccess';
import TroubleShootingLogoutAndResetSuccess from '@salesforce/label/c.TroubleShootingLogoutAndResetSuccess';
import TroubleShootingSecurityTaskSuccess from '@salesforce/label/c.TroubleShootingSecurityTaskSuccess';
import TroubleShootingConnectedAppAddSuccess from '@salesforce/label/c.TroubleShootingConnectedAppAddSuccess';
import TroubleShootingConnectedAppRemoveSuccess from '@salesforce/label/c.TroubleShootingConnectedAppRemoveSuccess';
import getLoginInformation from '@salesforce/apex/TroubleShootingController.getLoginInformation';
import triggerLogout from '@salesforce/apex/TroubleShootingController.triggerLogout';
import triggerChangeSecurityTask from '@salesforce/apex/TroubleShootingController.triggerChangeSecurityTask';
import triggerAuthorizeConnectedApp from '@salesforce/apex/TroubleShootingController.triggerAuthorizeConnectedApp';
import triggerDeAuthorizeConnectedApp from '@salesforce/apex/TroubleShootingController.triggerDeAuthorizeConnectedApp';
import {isEmpty} from 'c/utils';

export default class TroubleShooting extends LightningElement {
  docuSignLogo = DocuSignLogo;
  disconnectedLogo = DisconnectedLogo;
  isLoading = true;
  showToast = false;
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
  troubleShootingDisconnectAccountResetUsers = TroubleShootingDisconnectAccountResetUsers;
  troubleShootingDisconnectAccountResetUsersInfo = TroubleShootingDisconnectAccountResetUsersInfo;
  troubleShootingFolderPermissions = TroubleShootingFolderPermissions;
  troubleShootingFolderPermissionsInfo = TroubleShootingFolderPermissionsInfo;
  troubleShootingConnectedApp = TroubleShootingConnectedApp;
  troubleShootingConnectedAppInfo = TroubleShootingConnectedAppInfo;
  troubleShootingConnectedAppRemovePermissions = TroubleShootingConnectedAppRemovePermissions;
  troubleShootingConnectedAppRemovePermissionsInfo = TroubleShootingConnectedAppRemovePermissionsInfo;
  troubleShootingNoAccountConnected = TroubleShootingNoAccountConnected;
  troubleShootingError = TroubleShootingError;
  troubleShootingLogoutSuccess = TroubleShootingLogoutSuccess;
  troubleShootingLogoutAndResetSuccess = TroubleShootingLogoutAndResetSuccess;
  troubleShootingSecurityTaskSuccess = TroubleShootingSecurityTaskSuccess;
  troubleShootingConnectedAppAddSuccess = TroubleShootingConnectedAppAddSuccess;
  troubleShootingConnectedAppRemoveSuccess = TroubleShootingConnectedAppRemoveSuccess;

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

  triggerLogoutDoNotResetUsers() {
    this.isLoading = true;
    triggerLogout({
      resetUsers: false
    })
      .then(() => {
        this.toastMode = 'success';
        this.toastMessage = this.troubleShootingLogoutSuccess;
        this.showToast = true;
        setTimeout(function () {
          window.location.reload();
        }, 2000);
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
      });
  }

  triggerLogoutResetUsers() {
    this.isLoading = true;
    triggerLogout({
      resetUsers: true
    })
      .then(() => {
        this.toastMode = 'success';
        this.toastMessage = this.troubleShootingLogoutAndResetSuccess;
        this.showToast = true;
        setTimeout(function () {
          window.location.reload();
        }, 2000);
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
      });
  }

  triggerChangeSecurityTask() {
    this.isLoading = true;
    triggerChangeSecurityTask()
      .then(() => {
        this.toastMode = 'success';
        this.toastMessage = this.troubleShootingSecurityTaskSuccess;
        this.showToast = true;
        setTimeout(function () {
          window.location.reload();
        }, 2000);
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
      });
  }

  triggerAuthorizeConnectedApp() {
    this.isLoading = true;
    triggerAuthorizeConnectedApp()
      .then(() => {
        this.toastMode = 'success';
        this.toastMessage = this.troubleShootingConnectedAppAddSuccess;
        this.showToast = true;
        setTimeout(function () {
          window.location.reload();
        }, 2000);
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
      });
  }

  triggerDeAuthorizeConnectedApp() {
    this.isLoading = true;
    triggerDeAuthorizeConnectedApp()
      .then(() => {
        this.toastMode = 'success';
        this.toastMessage = this.troubleShootingConnectedAppRemoveSuccess;
        this.showToast = true;
        setTimeout(function () {
          window.location.reload();
        }, 2000);
      })
      .catch((exception) => {
        this.toastMode = 'error';
        this.toastMessage = exception.body.message;
        this.showToast = true;
        this.isLoading = false;
      });
  }
}