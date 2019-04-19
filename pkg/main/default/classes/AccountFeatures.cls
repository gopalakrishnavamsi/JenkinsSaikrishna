/**
 * Available DocuSign account features.
 */
public with sharing class AccountFeatures {
	@TestVisible
	private static final Integer FLAG_MERGE_FIELDS = 1;
	@TestVisible
	private static final Integer FLAG_SHARED_CUSTOM_TABS = 2;
	@TestVisible
	private static final Integer FLAG_SAVING_CUSTOM_TABS = 4;
	@TestVisible
	private static final Integer FLAG_DATA_FIELD_REGEXES = 8;
	@TestVisible
	private static final Integer FLAG_DATA_FIELD_SIZES = 16;
	@TestVisible
	private static final Integer FLAG_TAB_TEXT_FORMATTING = 32;
	@TestVisible
	private static final Integer FLAG_TAB_DATA_LABELS = 64;
	@TestVisible
	private static final Integer FLAG_SIGNING_GROUPS = 128;
	@TestVisible
	private static final Integer FLAG_SMS_AUTHENTICATION = 256;
	@TestVisible
	private static final Integer FLAG_TEMPLATES = 512;
	@TestVisible
	private static final Integer FLAG_BULK_SENDING = 1024;
	@TestVisible
	private static final Integer FLAG_IS_EXPIRED = 2048;

	private static AccountFeatures self = null;
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 1440; // 1 hour

	/**
	 * Whether merge fields are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean mergeFields { get; private set; }
	/**
	 * Whether shared custom tabs are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean sharedCustomTabs { get; private set; }
	/**
	 * Whether saved custom tabs are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean savingCustomTabs { get; private set; }
	/**
	 * Whether data field regular expressions are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean dataFieldRegexes { get; private set; }
	/**
	 * Whether data field sizes are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean dataFieldSizes { get; private set; }
	/**
	 * Whether custom tab text formatting is enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean tabTextFormatting { get; private set; }
	/**
	 * Whether custom tab data labels are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean tabDataLabels { get; private set; }
	/**
	 * Whether signing groups are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean signingGroups { get; private set; }
	/**
	 * Whether recipient SMS authentication is enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean smsAuthentication { get; private set; }
	/**
	 * Whether envelope templates are enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean templates { get; private set; }
	/**
	 * Whether bulk sending is enabled on the DocuSign account.
	 */
	@AuraEnabled
	public Boolean bulkSending { get; private set; }
	/**
	 * Whether trial account is expired or not.
	 */
	@AuraEnabled
	public Boolean isExpired { get; private set; }

	private AccountFeatures(final Integer features) {
		this.mergeFields = (features & FLAG_MERGE_FIELDS) == FLAG_MERGE_FIELDS;
		this.sharedCustomTabs = (features & FLAG_SHARED_CUSTOM_TABS) == FLAG_SHARED_CUSTOM_TABS;
		this.savingCustomTabs = (features & FLAG_SAVING_CUSTOM_TABS) == FLAG_SAVING_CUSTOM_TABS;
		this.dataFieldRegexes = (features & FLAG_DATA_FIELD_REGEXES) == FLAG_DATA_FIELD_REGEXES;
		this.dataFieldSizes = (features & FLAG_DATA_FIELD_SIZES) == FLAG_DATA_FIELD_SIZES;
		this.tabDataLabels = (features & FLAG_TAB_DATA_LABELS) == FLAG_TAB_DATA_LABELS;
		this.tabTextFormatting = (features & FLAG_TAB_TEXT_FORMATTING) == FLAG_TAB_TEXT_FORMATTING;
		this.signingGroups = (features & FLAG_SIGNING_GROUPS) == FLAG_SIGNING_GROUPS;
		this.smsAuthentication = (features & FLAG_SMS_AUTHENTICATION) == FLAG_SMS_AUTHENTICATION;
		this.templates = (features & FLAG_TEMPLATES) == FLAG_TEMPLATES;
		this.bulkSending = (features & FLAG_BULK_SENDING) == FLAG_BULK_SENDING;
		this.isExpired = (features & FLAG_IS_EXPIRED) == FLAG_IS_EXPIRED;
	}

	// Serialization objects for getSettings
	private class ApiAccountSetting {
		public String name;
		public String value;
	}

	private class ApiAccountSettings {
		public List<ApiAccountSetting> accountSettings;

		public Integer toExternalForm() {
			if (Collection.isEmpty(this.accountSettings)) return 0;

			Integer result = 0;
			for (ApiAccountSetting accountSetting : this.accountSettings) {
				if (accountSetting.name == 'allowMergeFields' && accountSetting.value == 'true') {
					result |= FLAG_MERGE_FIELDS;
				} else if (accountSetting.name == 'sharedCustomTabsEnabled' && accountSetting.value == 'true') {
					result |= FLAG_SHARED_CUSTOM_TABS;
				} else if (accountSetting.name == 'savingCustomTabsEnabled' && accountSetting.value == 'true') {
					result |= FLAG_SAVING_CUSTOM_TABS;
				} else if (accountSetting.name == 'dataFieldRegexEnabled' && accountSetting.value == 'true') {
					result |= FLAG_DATA_FIELD_REGEXES;
				} else if (accountSetting.name == 'dataFieldSizeEnabled' && accountSetting.value == 'true') {
					result |= FLAG_DATA_FIELD_SIZES;
				} else if (accountSetting.name == 'tabTextFormattingEnabled' && accountSetting.value == 'true') {
					result |= FLAG_TAB_TEXT_FORMATTING;
				} else if (accountSetting.name == 'allowSigningGroups' && accountSetting.value == 'true') {
					result |= FLAG_SIGNING_GROUPS;
				} else if (accountSetting.name == 'tabDataLabelEnabled' && accountSetting.value == 'true') {
					result |= FLAG_TAB_DATA_LABELS;
				} else if (accountSetting.name == 'enableSMSAuthentication' && accountSetting.value == 'true') {
					result |= FLAG_SMS_AUTHENTICATION;
				} else if (accountSetting.name == 'allowServerTemplates' && accountSetting.value == 'true') {
					result |= FLAG_TEMPLATES;
				} else if (accountSetting.name == 'allowBulkSend' && accountSetting.value == 'true') {
					result |= FLAG_BULK_SENDING;
				} else if (accountSetting.name == 'isExpired' && accountSetting.value == 'true') {
					result |= FLAG_IS_EXPIRED;
				}
			}
			return result;
		}
	}

	@TestVisible
	private class SettingsAPI extends ESignatureAPI {

		public SettingsAPI(
			final Url baseUrl,
			final UUID accountId) {

			super(baseUrl, 'v2', accountId);
		}

		public Integer getSettings() {
			final RestAPI.Response response = this.get('settings', RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get account settings: ' + response.error.toString());
				throw new APIException(response.error);
			}
			//return ((ApiAccountSettings)JSON.deserialize(response.body, ApiAccountSettings.class)).toExternalForm();
			ApiAccountSettings apiAccountSettings = (ApiAccountSettings)JSON.deserialize(response.body, ApiAccountSettings.class);

			final Account a = AccountService.getCurrentAccount();
			ApiAccountSetting apiAccountSetting = new ApiAccountSetting();
			apiAccountSetting.name = 'isExpired';
			if(a == null || a.isTrial == null || a.trialStatus == null || a.trialStatus.isExpired == null) {
				apiAccountSetting.value = 'false';
			} else {
				apiAccountSetting.value = String.valueOf(a.isTrial && a.trialStatus.isExpired);
			}
			apiAccountSettings.accountSettings.add(apiAccountSetting);
			return apiAccountSettings.toExternalForm();
		}
	}

	@TestVisible
	private static Integer resolveFeatures(
		final Integer configuredFeatures,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes) {

		Integer resolvedFeatures = 0;
		if (configuredFeatures == null
			|| lastChecked == null
			|| checkFrequencyMinutes == null
			|| lastChecked.addMinutes(checkFrequencyMinutes) <= Datetime.now()) {

			Credentials c = Credentials.getInstance();
			resolvedFeatures = new SettingsAPI(c.environment.eSignatureBaseUrl, c.account.id).getSettings();
			updateAccountSettings(resolvedFeatures, checkFrequencyMinutes);
		} else {
			resolvedFeatures = configuredFeatures;
		}

		return resolvedFeatures;
	}

	@future
	private static void updateAccountSettings (Integer resolvedFeatures, Integer checkFrequencyMinutes) {
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		settings.Features__c = resolvedFeatures;
		settings.FeaturesLastChecked__c = Datetime.now();
		settings.FeaturesCheckFrequency__c = checkFrequencyMinutes == null
			? DEFAULT_CHECK_FREQUENCY_MIN : checkFrequencyMinutes;
		upsert settings;
	}

	/**
	 * Retrieves DocuSign account features.
	 *
	 * @return A DocuSign account features instance.
	 */
	public static AccountFeatures getInstance() {
		if (self == null) {
			Integer features = 0;
			try {
				AccountSettings__c s = AccountSettings__c.getOrgDefaults();
				features = resolveFeatures(
					Integer.valueOf(s.Features__c),
					s.FeaturesLastChecked__c,
					Integer.valueOf(s.FeaturesCheckFrequency__c));
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to get account features');
			}
			self = new AccountFeatures(features);
		}
		return self;
	}
}
