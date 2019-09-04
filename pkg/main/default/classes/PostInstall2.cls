/**
* Initializes new custom settings in 2.0.
*/
public class PostInstall2 implements PostInstallScript {

	@TestVisible
	private static PostInstallResults initializeAccountSettings() {
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

		if (didInit) {
			update settings;
			result.endStepSuccess(Label.InitializeAccountSettings);
		} else {
			result.skipStep(Label.InitializeAccountSettings, Label.AlreadyComplete);
		}
		return result;
	}

	public Boolean shouldExecute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade) {

		return previousVersion != null
			&& previousVersion.major() < 2;
	}

	public PostInstallResults execute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade) {

		return new PostInstallResults().addResults(initializeAccountSettings());
	}
}