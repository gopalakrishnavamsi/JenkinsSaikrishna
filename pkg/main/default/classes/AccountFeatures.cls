/**
 * Available DocuSign account features.
 */
public with sharing class AccountFeatures extends ESignatureAPI {
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

	private static AccountFeatures self = null;
	private static final Integer DEFAULT_CHECK_FREQUENCY_MIN = 1440; // 1 hour

	private transient final Integer features;

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

	@TestVisible
	private AccountFeatures(final Credentials apiCredentials) {
		super(apiCredentials);

		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		this.features = resolveFeatures(
			Integer.valueOf(settings.Features__c),
			settings.FeaturesLastChecked__c,
			Integer.valueOf(settings.FeaturesCheckFrequency__c));
		this.mergeFields = (this.features & FLAG_MERGE_FIELDS) == FLAG_MERGE_FIELDS;
		this.sharedCustomTabs = (this.features & FLAG_SHARED_CUSTOM_TABS) == FLAG_SHARED_CUSTOM_TABS;
		this.savingCustomTabs = (this.features & FLAG_SAVING_CUSTOM_TABS) == FLAG_SAVING_CUSTOM_TABS;
		this.dataFieldRegexes = (this.features & FLAG_DATA_FIELD_REGEXES) == FLAG_DATA_FIELD_REGEXES;
		this.dataFieldSizes = (this.features & FLAG_DATA_FIELD_SIZES) == FLAG_DATA_FIELD_SIZES;
		this.tabDataLabels = (this.features & FLAG_TAB_DATA_LABELS) == FLAG_TAB_DATA_LABELS;
		this.tabTextFormatting = (this.features & FLAG_TAB_TEXT_FORMATTING) == FLAG_TAB_TEXT_FORMATTING;
		this.signingGroups = (this.features & FLAG_SIGNING_GROUPS) == FLAG_SIGNING_GROUPS;
		this.smsAuthentication = (this.features & FLAG_SMS_AUTHENTICATION) == FLAG_SMS_AUTHENTICATION;
		this.templates = (this.features & FLAG_TEMPLATES) == FLAG_TEMPLATES;
		this.bulkSending = (this.features & FLAG_BULK_SENDING) == FLAG_BULK_SENDING;
	}

	@TestVisible
	private Integer resolveFeatures(
		final Integer configuredFeatures,
		final Datetime lastChecked,
		final Integer checkFrequencyMinutes) {

		Integer resolvedFeatures = 0;
		if (configuredFeatures == null
			|| lastChecked == null
			|| checkFrequencyMinutes == null
			|| lastChecked.addMinutes(checkFrequencyMinutes) <= Datetime.now()) {

			try {
				resolvedFeatures = getFlags(getApiAccountFeatures());
				AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
				settings.Features__c = resolvedFeatures;
				settings.FeaturesLastChecked__c = Datetime.now();
				settings.FeaturesCheckFrequency__c = checkFrequencyMinutes == null
					? DEFAULT_CHECK_FREQUENCY_MIN : checkFrequencyMinutes;
				upsert settings;
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to get account features');
			}
		} else {
			resolvedFeatures = configuredFeatures;
		}

		return resolvedFeatures;
	}

	@TestVisible
	private static Integer getFlags(final ApiAccountFeatures accountFeatures) {
		Integer result = 0;
		if (accountFeatures != null && accountFeatures.accountSettings != null) {
			for (ApiAccountFeature accountSetting : accountFeatures.accountSettings) {
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
				}
			}
		}
		return result;
	}

	// Serialization objects for getFeatures
	@TestVisible
	private class ApiAccountFeature {
		public String name;
		public String value;
	}

	@TestVisible
	private class ApiAccountFeatures {
		public List<ApiAccountFeature> accountSettings;
	}

	@TestVisible
	private ApiAccountFeatures getApiAccountFeatures() {
		final RestAPI.Response response = this.get('settings', RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get account settings: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return (ApiAccountFeatures)JSON.deserialize(response.body, ApiAccountFeatures.class);
	}

	/**
	 * Retrieves DocuSign account features.
	 *
	 * @return A DocuSign account features instance.
	 */
	public static AccountFeatures getInstance() {
		if (self == null) {
			self = new AccountFeatures(Credentials.getInstance());
		}
		return self;
	}
}
