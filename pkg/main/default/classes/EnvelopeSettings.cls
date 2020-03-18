public with sharing class EnvelopeSettings {

	private static EnvelopeSettings self = null;
	public static final String CHATTER_DISABLED = 'Disabled';
	public static final String CHATTER_ENABLED_DEFAULT_OFF = 'EnabledDefaultOff';
	public static final String CHATTER_ENABLED_DEFAULT_ON = 'EnabledDefaultOn';
	public static final String CHATTER_ENABLED_ALWAYS_ON = 'EnabledAlwaysOn';

	public Boolean showRemindAndExpireSettings { get; private set; }
	public Boolean showTagButton { get; private set; }
	public Boolean showSendButton { get; private set; }
	public Boolean showAddFile { get; private set; }
	public Boolean allowEditEmailSubject { get; private set; }
	public Boolean allowEditEmailMessage { get; private set; }
	public Boolean allowRecipientLanguageSelection {
		get {
			return Localization.isEmailLocalizationEnabled();
		}
	}
	public List<Recipient.EmailSettings> emailLocalizations { get; private set; }
	public Boolean isSmsEnabled { get; private set; }
	public Boolean allowSequentialSignNow { get; private set; }
	public String chatterSetting { get; private set; }
	public Boolean isChatterEnabled {
		get {
			return Salesforce.isChatterEnabled
				&& String.isNotBlank(this.chatterSetting)
				&& this.chatterSetting.endsWith('On');
		}
	}
	public Boolean isChatterAlwaysOn {
		get {
			return Salesforce.isChatterEnabled
				&& this.chatterSetting == CHATTER_ENABLED_ALWAYS_ON;
		}
	}
	public Boolean showChatter {
		get {
			return Salesforce.isChatterEnabled
				&& String.isNotBlank(this.chatterSetting)
				&& this.chatterSetting.startsWith('Enabled')
				&& !this.isChatterAlwaysOn;
		}
	}
	public ChatterEvents chatterPostEvents { get; private set; }
	public Localization.ChatterText chatterLocalization { get; private set; }
	public List<Recipient.Role> defaultRoles { get; private set; }
	public String errorMessage { get; private set; }
	public Boolean isValid {
		get {
			return String.isBlank(this.errorMessage);
		}
	}

	public EnvelopeSettings(
		final Boolean showTagButton,
		final Boolean showSendButton,
		final Boolean showAddFile,
		final Boolean showRemindAndExpireSettings,
		final Boolean allowEditEmailSubject,
		final Boolean allowEditEmailMessage,
		final List<Recipient.EmailSettings> emailLocalizations,
		final Boolean isSmsEnabled,
		final Boolean allowSequentialSignNow,
		final String chatterSetting,
		final ChatterEvents chatterPostEvents,
		final Localization.ChatterText chatterLocalization,
		final List<Recipient.Role> defaultRoles,
		final String errorMessage) {

		this.showTagButton = showTagButton;
		this.showSendButton = showSendButton;
		this.showAddFile = showAddFile;
		this.showRemindAndExpireSettings = showRemindAndExpireSettings;
		this.allowEditEmailSubject = allowEditEmailSubject;
		this.allowEditEmailMessage = allowEditEmailMessage;
		this.emailLocalizations = emailLocalizations;
		this.isSmsEnabled = isSmsEnabled;
		this.allowSequentialSignNow = allowSequentialSignNow;
		this.chatterSetting = chatterSetting;
		this.chatterPostEvents = chatterPostEvents;
		this.chatterLocalization = chatterLocalization;
		this.defaultRoles = defaultRoles;
		this.errorMessage = errorMessage;
	}

	private static Boolean isEnabled(final Boolean adminEnabled, final Boolean overrideEnabled) {
		if (adminEnabled) { // Must be explicitly disabled in query string to override admin enabled setting
			return overrideEnabled != false;
		} else { // Must be explicitly enabled in query string to override admin disabled setting
			return overrideEnabled == true;
		}
	}

	@TestVisible
	private static String getChatterSetting(final Boolean isEnabled, final Boolean isDefaultOn, final Boolean isAlwaysOn) {
		String result = CHATTER_DISABLED;
		if (Salesforce.isChatterEnabled && isEnabled == true) {
			result = isAlwaysOn == true ? CHATTER_ENABLED_ALWAYS_ON :
				isDefaultOn == true ? CHATTER_ENABLED_DEFAULT_ON : CHATTER_ENABLED_DEFAULT_OFF;
		}
		return result;
	}

	public EnvelopeSettings mergeWith(final EnvelopeConfiguration.VisibilitySettings overrides) {
		if (overrides == null) return this;

		// Custom button Boolean parameters will be null if not explicitly set in query string.
		return new EnvelopeSettings(
			isEnabled(this.showTagButton, overrides.showTagButton),
			isEnabled(this.showSendButton, overrides.showSendButton),
			overrides.showAddFile == true,
			isEnabled(this.showRemindAndExpireSettings, overrides.showRemindExpire),
			isEnabled(this.allowEditEmailSubject, overrides.showEmailSubject),
			isEnabled(this.allowEditEmailMessage, overrides.showEmailMessage),
			this.emailLocalizations,
			this.isSmsEnabled,
			this.allowSequentialSignNow,
			getChatterSetting(
				isEnabled(this.isChatterEnabled, overrides.showChatter),
				this.chatterSetting == CHATTER_ENABLED_DEFAULT_ON,
				this.isChatterAlwaysOn),
			ChatterEvents.getInstance(),
			Localization.getChatterText(),
			this.defaultRoles,
			this.errorMessage);
	}

	@TestVisible
	private static List<Recipient.Role> getDefaultRoles() {
		List<Recipient.Role> result = new List<Recipient.Role>();
		for (RoleSettings__c s : RoleSettings__c.getAll().values()) {
			result.add(new Recipient.Role(s.Name, Integer.valueOf(s.Value__c)));
		}
		return result;
	}

	public static EnvelopeSettings getInstance() {
		if (self == null) {
			String errorMessage = null;
			try {
				EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
				self = new EnvelopeSettings(
					settings == null || settings.HideTagButton__c == false,
					settings == null || settings.HideSendButton__c == false,
					false,
					settings == null || (settings.HideRemindExpire__c == false
						&& settings.UseNotificationDefaults__c == false),
					settings == null || settings.HideEmailSubject__c == false,
					settings == null || settings.HideEmailMessage__c == false,
					Localization.getEmailSettings(),
					settings == null ? false : settings.IsSmsEnabled__c,
					settings == null ? false : settings.AllowSequentialSignNow__c,
					Salesforce.isChatterEnabled ? settings.Chatter__c : CHATTER_DISABLED,
					ChatterEvents.getInstance(),
					Localization.getChatterText(),
					getDefaultRoles(),
					errorMessage);
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to get settings');
				self = new EnvelopeSettings(true, true, false, true, true, true, null, false, false, null, null, null,
					null, ex.getMessage());
			}
		}
		return self;
	}

	@TestVisible
	private static String getCanonicalChatterSetting(final String s) {
		// Get canonicalized Chatter setting
		String result = CHATTER_DISABLED;
		if (Salesforce.isChatterEnabled && String.isNotBlank(s)) {
			String s2 = s.trim();
			if (s2 == CHATTER_ENABLED_DEFAULT_OFF) {
				result = CHATTER_ENABLED_DEFAULT_OFF;
			} else if (s2 == CHATTER_ENABLED_DEFAULT_ON) {
				result = CHATTER_ENABLED_DEFAULT_ON;
			} else if (s2 == CHATTER_ENABLED_ALWAYS_ON) {
				result = CHATTER_ENABLED_ALWAYS_ON;
			}
		}
		return result;
	}

	public static EnvelopeSettings save(final EnvelopeSettings settings) {
		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);
		EnvelopeSettings__c s = EnvelopeSettings__c.getOrgDefaults();
		s.HideTagButton__c = settings.showTagButton == false;
		s.HideSendButton__c = settings.showSendButton == false;
		s.HideRemindExpire__c = settings.showRemindAndExpireSettings == false;
		s.HideEmailSubject__c = settings.allowEditEmailSubject == false;
		s.HideEmailMessage__c = settings.allowEditEmailMessage == false;
		s.IsSmsEnabled__c = settings.isSmsEnabled == true;
		s.AllowSequentialSignNow__c = settings.allowSequentialSignNow == true;
		s.Chatter__c = getCanonicalChatterSetting(settings.chatterSetting);
		upsert s;

		if (settings.emailLocalizations != null) {
			Localization.save(settings.emailLocalizations);
		}

		if (settings.chatterPostEvents != null) {
			ChatterEvents.save(settings.chatterPostEvents);
		}

		if (settings.chatterLocalization != null) {
			Localization.save(settings.chatterLocalization);
		}

		delete RoleSettings__c.getAll().values();
		if (Collection.isNotEmpty(settings.defaultRoles)) {
			List<RoleSettings__c> roleSettings = new List<RoleSettings__c>();
			Integer roleValue = 1;
			for (Recipient.Role r : settings.defaultRoles) {
				if (String.isBlank(r.name)) {
					LoggerService.getInstance().warn('Skipping role with blank name');
				} else {
					roleSettings.add(new RoleSettings__c(Name = r.name, Value__c = roleValue++));
				}
			}
			insert roleSettings;
		}

		self = null;
		return getInstance();
	}

	public static Envelope.Options getOptions(final Boolean sendNow) {
		EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
		return new Envelope.Options(
			sendNow,
			settings != null && settings.AddAnchorTags__c == true,
			settings != null && settings.FetchDocuments__c
				&& Salesforce.isApiSupported && Permissions.isApiEnabled(),
			settings != null && settings.UseNotificationDefaults__c == true);
	}
}
