/**
* Initializes new custom settings in 2.0.
*/
public class PostInstall2 implements PostInstallScript {

	@TestVisible
	private static PostInstallResults initializeAccountSettings(final Id organizationId) {
		Boolean didInit = false;
		PostInstallResults result = new PostInstallResults();
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();

		if (settings.IsESignatureEnabled__c != true) {
			settings.IsESignatureEnabled__c = true;
			didInit = true;
		}

		if (String.isBlank(settings.EncryptionKey__c)) {
			settings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
			didInit = true;
		}

		if (String.isBlank(settings.OrganizationId__c)) {
			settings.OrganizationId__c = organizationId;
			didInit = true;
		}

		if (didInit) {
			update settings;
			result.endStepSuccess(Label.InitializeAccountSettings);
		} else {
			result.skipStep(Label.InitializeAccountSettings, Label.AlreadyComplete);
		}
		return result;
	}

	public Boolean shouldExecute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		return previousVersion != null
			&& previousVersion.major() < 2;
	}

	public PostInstallResults execute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		return new PostInstallResults().addResults(initializeAccountSettings(organizationId));
	}
}
