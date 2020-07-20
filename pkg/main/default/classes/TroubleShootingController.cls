public with sharing class TroubleShootingController extends Controller {
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
				accountSettings.AccountNumber__c != null ? 	(long)accountSettings.AccountNumber__c : null,
				String.isNotBlank(accountSettings.Environment__c) ? 'connected' : 'disconnected'
			);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get login information.');
		}
	}

}