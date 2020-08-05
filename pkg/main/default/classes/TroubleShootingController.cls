public with sharing class TroubleShootingController extends Controller {
	//The Salesforce user invoking these controller methods needs to be assigned with the DocuSign Administrator Permission Set
	@TestVisible
	public class LoginInformation {

		@AuraEnabled
		public String environment { get; private set; }

		@AuraEnabled
		public String accountEmail { get; private set; }

		@AuraEnabled
		public Long accountNumber { get; private set; }

		@AuraEnabled
		public String status { get; private set; }

		public LoginInformation(
			final String environment,
			final String accountEmail,
			final Long accountNumber,
			final String status) {

			this.environment = environment;
			this.accountEmail = accountEmail;
			this.accountNumber = accountNumber;
			this.status = status;
		}
	}

	@AuraEnabled
	public static LoginInformation getLoginInformation() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			return new LoginInformation(
				String.isNotBlank(accountSettings.Environment__c) ? accountSettings.Environment__c : null,
				String.isNotBlank(accountSettings.Email__c) ? accountSettings.Email__c : null,
				accountSettings.AccountNumber__c != null ? (long)accountSettings.AccountNumber__c : null,
				String.isNotBlank(accountSettings.Environment__c) ? 'connected' : 'disconnected'
			);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get login information.');
		}
	}

	//logout from currently connected DocuSign Account
	//resetUsers Boolean flag will determine whether or not to also reset user credentials and clear any permission set assignments.
	//useful if setup page is currently inaccessible due to any reason.
	@AuraEnabled
	public static Boolean triggerLogout(final Boolean resetUsers) {
		try {
			AuthService.resetAccount(resetUsers);
			return true;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to trigger Logout.');
		}
	}
	//call the springCM API to set the security on root level folder
	//this needs to happen in order to ensure that DocuSign Apps Launcher users other than the Setup User
	//have appropriate access to SpringCM work items
	//this can be triggered on an adhoc basis from the troubleshooting page if customers observe 401 errors with
	//respect to accessing Negotiate Work Items / Folders
	@AuraEnabled
	public static Boolean triggerChangeSecurityTask() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return NegotiateAPI.getInstance().setRootLevelFolderSecurity();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to trigger ChangeSecurityTask.');
		}
	}

	//Admin Authorization for the DocuSign connected application. The app is authorized for the
	//DocuSign Administrator and DocuSign User permission sets.
	//this can be triggered on an adhoc basis to ensure the Connected app permissions have been added to DAL Permissions sets.
	@AuraEnabled
	public static Boolean triggerAuthorizeConnectedApp() {
		try {
			PlatformAuthorizationService.authorize();
			return true;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to trigger AuthorizeConnectedApp.');
		}
	}

	//Removes admin authorization for the DocuSign connected application. The app is deauthorized for the
	//DocuSign Administrator and DocuSign User permission sets.
	//this can be triggered on an adhoc basis to ensure the Connected app permissions have been removed from DAL Permissions sets.
	@AuraEnabled
	public static Boolean triggerDeAuthorizeConnectedApp() {
		try {
			PlatformAuthorizationService.deauthorize();
			return true;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to trigger DeAuthorizeConnectedApp.');
		}
	}

}