/**
 * No sharing declaration here as it's run as part of post-install. "with sharing" or "inherited sharing" causes
 * package installation to fail with "Insufficient Privileges" error. Some code is duplicated to avoid instantiating
 * "with sharing" classes.
 */
public class ConnectConfigurationPostInstall implements PostInstallScript {

	private static final Integer FLAG_CONNECT = 32;

	@TestVisible
	private static Boolean isConnectEnabled() {
		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		ProductSettings__c eSignSettings = ProductSettings__c.getInstance(Product.ESIGNATURE);
		return accountSettings != null
			&& eSignSettings != null
			&& String.isNotBlank(accountSettings.AccountId__c)
			&& String.isNotBlank(accountSettings.Environment__c)
			&& String.isNotBlank(accountSettings.ESignatureBaseUrl__c)
			&& eSignSettings.Features__c != null
			&& (Integer.valueOf(eSignSettings.Features__c) & FLAG_CONNECT) == FLAG_CONNECT;
	}

	public Boolean shouldExecute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		// Only execute if upgrading from < v2.5 and Connect is enabled for the account.
		return isUpgrade
			&& previousVersion != null
			&& previousVersion.major() <= 2
			&& previousVersion.minor() < 5
			&& isConnectEnabled();
	}

	public PostInstallResults execute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		if (!this.shouldExecute(organizationId, installerId, previousVersion, isPush, isUpgrade)) {
			return new PostInstallResults().skipStep(Label.CreateConnectConfiguration, Label.PostInstallCriteriaNotMet);
		}

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.CreateConnectConfiguration__c = true;
		update accountSettings;

		PostInstallResults result = new PostInstallResults();
		result.endStepSuccess(Label.CreateConnectConfiguration);

		return result;
	}
}
