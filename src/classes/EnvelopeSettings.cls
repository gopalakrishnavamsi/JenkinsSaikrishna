public with sharing class EnvelopeSettings {

	private static EnvelopeSettings self = null;
	private static List<Recipient.Role> DEFAULT_ROLES = null;

	public Boolean isChatterEnabled { get; private set; }
	public Boolean isChatterAlwaysOn { get; private set; }
	public Boolean showRemindAndExpireSettings { get; private set; }
	public Boolean showTagButton { get; private set; }
	public Boolean showSendButton { get; private set; }
	public Boolean showAddAttachment { get; private set; }
	public Boolean allowEditEmailSubject { get; private set; }
	public Boolean allowEditEmailMessage { get; private set; }
	public Boolean allowRecipientLanguageSelection { get; private set; }
	public List<Recipient.EmailSettings> emailSettings { get; private set; }
	public List<Recipient.Role> defaultRoles { get; private set; }
	public Boolean smsAuthentication { get; private set; }
	public String errorMessage { get; private set; }
	public Boolean isValid {
		get {
			return String.isBlank(this.errorMessage);
		}
	}

	@TestVisible
	private EnvelopeSettings(final Boolean isChatterEnabled, final Boolean isChatterAlwaysOn,
		final Boolean showTagButton, final Boolean showSendButton, final Boolean showAddAttachment,
		final Boolean showRemindAndExpireSettings, final Boolean allowEditEmailSubject,
		final Boolean allowEditEmailMessage, final Boolean allowRecipientLanguageSelection,
		final List<Recipient.EmailSettings> emailSettings, final List<Recipient.Role> defaultRoles,
		final Boolean smsAuthentication, final String errorMessage) {

		this.isChatterEnabled = isChatterEnabled;
		this.isChatterAlwaysOn = isChatterAlwaysOn;
		this.showTagButton = showTagButton;
		this.showSendButton = showSendButton;
		this.showAddAttachment = showAddAttachment;
		this.showRemindAndExpireSettings = showRemindAndExpireSettings;
		this.allowEditEmailSubject = allowEditEmailSubject;
		this.allowEditEmailMessage = allowEditEmailMessage;
		this.allowRecipientLanguageSelection = allowRecipientLanguageSelection;
		this.emailSettings = emailSettings;
		this.defaultRoles = defaultRoles;
		this.smsAuthentication = smsAuthentication;
		this.errorMessage = errorMessage;
	}

	@TestVisible
	private static List<Recipient.Role> getDefaultRoles() {
		if (DEFAULT_ROLES == null) {
			DEFAULT_ROLES = new List<Recipient.Role>();
			for (RoleSettings__c s : RoleSettings__c.getAll().values()) {
				DEFAULT_ROLES.add(new Recipient.Role(s.Name, Integer.valueOf(s.Value__c)));
			}
			DEFAULT_ROLES.sort();
		}
		return DEFAULT_ROLES;
	}

	private static Boolean isEnabled(final Boolean adminEnabled, final Boolean overrideEnabled) {
		if (adminEnabled) { // Must be explicitly disabled in query string to override admin enabled setting
			return overrideEnabled != false;
		} else { // Must be explicitly enabled in query string to override admin disabled setting
			return overrideEnabled == true;
		}
	}

	public EnvelopeSettings mergeWith(final EnvelopeConfiguration.VisibilitySettings overrides) {
		if (overrides == null) return this;

		// Custom button Boolean parameters will be null if not explicitly set in query string.
		return new EnvelopeSettings(
			isEnabled(this.isChatterEnabled, overrides.showChatter),
			this.isChatterEnabled && this.isChatterAlwaysOn,
			isEnabled(this.showTagButton, overrides.showTagButton),
			isEnabled(this.showSendButton, overrides.showSendButton),
			overrides.showAddAttachment == true,
			isEnabled(this.showRemindAndExpireSettings, overrides.showRemindExpire),
			isEnabled(this.allowEditEmailSubject, overrides.showEmailSubject),
			isEnabled(this.allowEditEmailMessage, overrides.showEmailMessage),
			this.allowRecipientLanguageSelection,
			this.emailSettings,
			this.defaultRoles,
			this.smsAuthentication,
			this.errorMessage);
	}

	public static EnvelopeSettings getInstance() {
		if (self == null) {
			String errorMessage = null;
			try {
				EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
				self = new EnvelopeSettings(
					Salesforce.isChatterEnabled && settings != null && String.isNotBlank(settings.Chatter__c)
						&& settings.Chatter__c.startsWith('Enabled'),
					Salesforce.isChatterEnabled && settings != null && settings.Chatter__c == 'EnabledAlwaysOn',
					settings == null || settings.HideTagButton__c == false,
					settings == null || settings.HideSendButton__c == false,
					false,
					settings == null || (settings.HideRemindExpire__c == false
						&& settings.UseNotificationDefaults__c == false),
					settings == null || settings.HideEmailSubject__c == false,
					settings == null || settings.HideEmailMessage__c == false,
					settings != null && Localization.isEmailLocalizationEnabled(),
					settings == null ? null : Localization.getEmailSettings(),
					settings == null ? null : EnvelopeSettings.getDefaultRoles(),
					settings == null ? false : settings.IsSmsEnabled__c,
					errorMessage);
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to get settings');
				self = new EnvelopeSettings(false, false, true, true, false, true, true, true, false, null, null,
					false, ex.getMessage());
			}
		}
		return self;
	}

	public static Envelope.Options getOptions(final Boolean sendNow) {
		EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
		return new Envelope.Options(
			sendNow,
			settings != null && settings.AddAnchorTags__c == true,
			settings != null && settings.FetchDocuments__c == true,
			settings != null && settings.UseNotificationDefaults__c == true);
	}
}
