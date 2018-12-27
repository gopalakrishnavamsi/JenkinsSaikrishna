/**
 * Source of truth for i18n-related operations.
 */
public with sharing class Localization {

	private static final SObjectType TYPE_ENVELOPE_LOCALIZATION = EnvelopeLocalization__c.getSObjectType();
	@TestVisible
	private static Boolean isEmailEnabled;

	public class ChatterText {
		public String envelopeSent { get; private set; }
		public String envelopeDelivered { get; private set; }
		public String envelopeCompleted { get; private set; }
		public String envelopeDeclined { get; private set; }
		public String envelopeVoided { get; private set; }
		public String recipientSent { get; private set; }
		public String recipientDelivered { get; private set; }
		public String recipientCompleted { get; private set; }
		public String recipientSigned { get; private set; }
		public String recipientDeclined { get; private set; }

		public ChatterText(final String envelopeSent, final String envelopeDelivered, final String envelopeCompleted,
			final String envelopeDeclined, final String envelopeVoided, final String recipientSent,
			final String recipientDelivered, final String recipientCompleted, final String recipientSigned,
			final String recipientDeclined) {

			this.envelopeSent = envelopeSent;
			this.envelopeDelivered = envelopeDelivered;
			this.envelopeCompleted = envelopeCompleted;
			this.envelopeDeclined = envelopeDeclined;
			this.envelopeVoided = envelopeVoided;
			this.recipientSent = recipientSent;
			this.recipientDelivered = recipientDelivered;
			this.recipientCompleted = recipientCompleted;
			this.recipientSigned = recipientSigned;
			this.recipientDeclined = recipientDeclined;
		}

		public String getEnvelopeStatusText(final String s) {
			String statusText = null;
			if (String.isNotBlank(s)) {
				if (s == Envelope.STATUS_SENT) {
					statusText = this.envelopeSent;
				} else if (s == Envelope.STATUS_DELIVERED) {
					statusText = this.envelopeDelivered;
				} else if (s == Envelope.STATUS_COMPLETED) {
					statusText = this.envelopeCompleted;
				} else if (s == Envelope.STATUS_DECLINED) {
					statusText = this.envelopeDeclined;
				} else if (s == Envelope.STATUS_VOIDED) {
					statusText = this.envelopeVoided;
				}
			}
			return statusText;
		}

		public String getRecipientStatusText(final String s) {
			String statusText = null;
			if (String.isNotBlank(s)) {
				if (s == Recipient.STATUS_SENT) {
					statusText = this.recipientSent;
				} else if (s == Recipient.STATUS_DELIVERED) {
					statusText = this.recipientDelivered;
				} else if (s == Recipient.STATUS_COMPLETED) {
					statusText = this.recipientCompleted;
				} else if (s == Recipient.STATUS_DECLINED) {
					statusText = this.recipientDeclined;
				} else if (s == Recipient.STATUS_SIGNED) {
					statusText = this.recipientSigned;
				}
			}
			return statusText;
		}
	}

	public class ChatterSettings {
		public String language { get; private set; }
		public String languageLabel { get; private set; }
		public ChatterText text { get; private set; }

		public ChatterSettings(final String language, final String languageLabel, final ChatterText text) {
			this.language = language;
			this.languageLabel = languageLabel;
			this.text = text;
		}
	}

	// Languages
	public static final String EN = 'en';
	public static final String DE = 'de';
	public static final String ES = 'es';
	public static final String FR = 'fr';
	public static final String IT = 'it';
	public static final String JA = 'ja';
	public static final String KO = 'ko';
	public static final String NL = 'nl';
	public static final String PT_BR = 'pt_BR';
	public static final String RU = 'ru';
	public static final String ZH_CN = 'zh_CN';
	public static final String CURRENT = 'CURRENT'; // that's only for chatter text (current language settings)
	private static final Map<String, String> LANGUAGE_TO_LABEL;
	public static final String DEFAULT_LANGUAGE;

	static {
		LANGUAGE_TO_LABEL = new Map<String, String> {
			EN => Label.English,
			DE => Label.German,
			ES => Label.Spanish,
			FR => Label.French,
			IT => Label.Italian,
			JA => Label.Japanese,
			KO => Label.Korean,
			NL => Label.Dutch,
			PT_BR => Label.PortugueseBrazilian,
			RU => Label.Russian,
			ZH_CN => Label.ChineseSimplified
		};

		String language = getCurrentLanguage();
		DEFAULT_LANGUAGE = LANGUAGE_TO_LABEL.containsKey(language) ? language : EN;
		isEmailEnabled = [SELECT COUNT() FROM EnvelopeLocalization__c WHERE Name != NULL LIMIT 100] > 1;
	}

	private static final Map<String, Recipient.EmailSettings> EMAIL_SETTINGS = new Map<String, Recipient.EmailSettings>();
	private static Boolean isDirty = true;

	@TestVisible
	private static List<EnvelopeLocalization__c> getOrgEmailSettings() {
		Permissions.verifyIsQueryable(TYPE_ENVELOPE_LOCALIZATION, new List<String> {
			'Name', 'Language__c', 'EmailSubject__c', 'EmailMessage__c'
		});

		return [
			SELECT Id, Name, Language__c, EmailSubject__c, EmailMessage__c
			FROM EnvelopeLocalization__c
			LIMIT 100
		];
	}

	public static Set<String> getAllLanguages() {
		return LANGUAGE_TO_LABEL.keySet();
	}

	public static String getLabel(final String language) {
		String label = String.isBlank(language) ? null : LANGUAGE_TO_LABEL.get(language);
		return String.isBlank(label) ? '' : label;
	}

	private static Map<String, Recipient.EmailSettings> getEmailSettingsMap() {
		if (isDirty) {
			EMAIL_SETTINGS.clear();
			for (EnvelopeLocalization__c config : getOrgEmailSettings()) {
				EMAIL_SETTINGS.put(config.Language__c, new Recipient.EmailSettings(
					config.Language__c,
					config.Name,
					config.EmailSubject__c,
					config.EmailMessage__c));
			}
			if (!EMAIL_SETTINGS.containsKey(DEFAULT_LANGUAGE)) {
				Localization__mdt md = [
					SELECT EmailSubject__c, EmailMessage__c
					FROM Localization__mdt
					WHERE DeveloperName = :DEFAULT_LANGUAGE
				];
				EMAIL_SETTINGS.put(DEFAULT_LANGUAGE, new Recipient.EmailSettings(
					DEFAULT_LANGUAGE,
					LANGUAGE_TO_LABEL.get(DEFAULT_LANGUAGE),
					md.EmailSubject__c,
					md.EmailMessage__c));
			}
			isDirty = false;
			isEmailEnabled = EMAIL_SETTINGS.size() > 1;
		}
		return EMAIL_SETTINGS;
	}

	public static List<Recipient.EmailSettings> getEmailSettings() {
		return getEmailSettingsMap().values();
	}

	public static Boolean isEmailLocalizationEnabled() {
		return isEmailEnabled;
	}

	public static String getCurrentLanguage() {
		String language = UserInfo.getLanguage();
		if (String.isNotBlank(language)
			&& language.length() >= 2
			&& language != 'zh_CN'
			&& language != 'pt_BR') {

			language = language.substring(0, 2);
		}
		return language;
	}

	public static Recipient.EmailSettings getEmailSettingsForCurrentLanguage() {
		Recipient.EmailSettings settings = getEmailSettings(getCurrentLanguage());
		if (settings == null) settings = getEmailSettings(DEFAULT_LANGUAGE);
		if (settings == null) throw new DocuSignException(Label.UnrecognizedLanguageCode);
		return settings;
	}

	@TestVisible
	private static Recipient.EmailSettings getEmailSettings(final String language) {
		return getEmailSettingsMap().get(language);
	}

	public static List<Recipient.EmailSettings> save(final List<Recipient.EmailSettings> emailSettings) {
		if (emailSettings == null) throw new DocuSignException(Label.UndefinedArgument);

		List<String> fields = new List<String> { 'Name', 'Language__c', 'EmailSubject__c', 'EmailMessage__c' };
		Permissions.verifyIsCreateable(TYPE_ENVELOPE_LOCALIZATION, fields);
		Permissions.verifyIsUpdateable(TYPE_ENVELOPE_LOCALIZATION, fields);
		Permissions.verifyIsDeletable(TYPE_ENVELOPE_LOCALIZATION);

		Map<String, EnvelopeLocalization__c> current = new Map<String, EnvelopeLocalization__c>();
		for (EnvelopeLocalization__c el : [
			SELECT Name, Language__c, EmailSubject__c, EmailMessage__c
			FROM EnvelopeLocalization__c
			LIMIT 1000
		]) {
			current.put(el.Language__c, el);
		}

		List<EnvelopeLocalization__c> toUpsert = new List<EnvelopeLocalization__c>();
		for (Recipient.EmailSettings s : emailSettings) {
			ValidationResult vr = validate(s);
			if (!vr.isValid) {
				throw new ValidationException(Label.InvalidEmailSettings, vr);
			}

			if (current.containsKey(s.language)) {
				EnvelopeLocalization__c loc = current.get(s.language);
				loc.Name = LANGUAGE_TO_LABEL.get(s.language);
				loc.EmailSubject__c = s.subject;
				loc.EmailMessage__c = s.message;
				toUpsert.add(loc);
			} else {
				toUpsert.add(new EnvelopeLocalization__c(
					Name = LANGUAGE_TO_LABEL.get(s.language),
					Language__c = s.language,
					EmailSubject__c = s.subject,
					EmailMessage__c = s.message));
			}
			current.remove(s.language); // Remaining settings are to be deleted.
		}
		current.remove(DEFAULT_LANGUAGE); // Ensure default localization is not deleted

		upsert toUpsert;
		delete current.values();
		isDirty = true;

		return getEmailSettings();
	}

	public static List<Recipient.EmailSettings> getDefaultEmailSettings() {
		List<Recipient.EmailSettings> result = new List<Recipient.EmailSettings>();
		for (Localization__mdt l : [
			SELECT DeveloperName, EmailSubject__c, EmailMessage__c
			FROM Localization__mdt
			LIMIT 1000
		]) {
			result.add(new Recipient.EmailSettings(
				l.DeveloperName,
				LANGUAGE_TO_LABEL.get(l.DeveloperName),
				l.EmailSubject__c,
				l.EmailMessage__c));
		}
		return result;
	}

	public static Recipient.EmailSettings getDefaultEmailSettings(final String language) {
		List<Localization__mdt> mds = [
			SELECT EmailSubject__c, EmailMessage__c
			FROM Localization__mdt
			WHERE DeveloperName = :language
		];
		if (Collection.isEmpty(mds)) {
			throw new DocuSignException(Label.UnrecognizedLanguageCode);
		}

		return new Recipient.EmailSettings(
			language,
			LANGUAGE_TO_LABEL.get(language),
			mds[0].EmailSubject__c,
			mds[0].EmailMessage__c);
	}

	/**
	 * Gets chatter text localized to specified language code
	 */
	public static ChatterText getDefaultChatterText(final String language) {
		List<Localization__mdt> mds = [
			SELECT ChatterEnvelopeSent__c,
				ChatterEnvelopeDelivered__c,
				ChatterEnvelopeCompleted__c,
				ChatterEnvelopeDeclined__c,
				ChatterEnvelopeVoided__c,
				ChatterRecipientSent__c,
				ChatterRecipientDelivered__c,
				ChatterRecipientCompleted__c,
				ChatterRecipientSigned__c,
				ChatterRecipientDeclined__c
			FROM Localization__mdt
			WHERE DeveloperName = :language
		];
		if (Collection.isEmpty(mds)) throw new DocuSignException(Label.UnrecognizedLanguageCode);

		Localization__mdt md = mds[0];
		return new ChatterText(
			md.ChatterEnvelopeSent__c,
			md.ChatterEnvelopeDelivered__c,
			md.ChatterEnvelopeCompleted__c,
			md.ChatterEnvelopeDeclined__c,
			md.ChatterEnvelopeVoided__c,
			md.ChatterRecipientSent__c,
			md.ChatterRecipientDelivered__c,
			md.ChatterRecipientCompleted__c,
			md.ChatterRecipientSigned__c,
			md.ChatterRecipientDeclined__c);
	}

	public static ChatterText getChatterText() {
		ChatterSettings__c settings = ChatterSettings__c.getOrgDefaults();
		Localization__mdt md = [
			SELECT
				ChatterEnvelopeSent__c,
				ChatterEnvelopeDelivered__c,
				ChatterEnvelopeCompleted__c,
				ChatterEnvelopeDeclined__c,
				ChatterEnvelopeVoided__c,
				ChatterRecipientSent__c,
				ChatterRecipientDelivered__c,
				ChatterRecipientCompleted__c,
				ChatterRecipientSigned__c,
				ChatterRecipientDeclined__c
			FROM Localization__mdt
			WHERE DeveloperName = :DEFAULT_LANGUAGE
		];
		return new ChatterText(
			String.isNotBlank(settings.EnvelopeSent__c) ? settings.EnvelopeSent__c : md.ChatterEnvelopeSent__c,
			String.isNotBlank(settings.EnvelopeDelivered__c) ? settings.EnvelopeDelivered__c : md.ChatterEnvelopeDelivered__c,
			String.isNotBlank(settings.EnvelopeCompleted__c) ? settings.EnvelopeCompleted__c : md.ChatterEnvelopeCompleted__c,
			String.isNotBlank(settings.EnvelopeDeclined__c) ? settings.EnvelopeDeclined__c : md.ChatterEnvelopeDeclined__c,
			String.isNotBlank(settings.EnvelopeVoided__c) ? settings.EnvelopeVoided__c : md.ChatterEnvelopeVoided__c,
			String.isNotBlank(settings.RecipientSent__c) ? settings.RecipientSent__c : md.ChatterRecipientSent__c,
			String.isNotBlank(settings.RecipientDelivered__c) ? settings.RecipientDelivered__c : md.ChatterRecipientDelivered__c,
			String.isNotBlank(settings.RecipientCompleted__c) ? settings.RecipientCompleted__c : md.ChatterRecipientCompleted__c,
			String.isNotBlank(settings.RecipientSigned__c) ? settings.RecipientSigned__c : md.ChatterRecipientSigned__c,
			String.isNotBlank(settings.RecipientDeclined__c) ? settings.RecipientDeclined__c : md.ChatterRecipientDeclined__c);
	}

	public static void save(final ChatterText chatterText) {
		if (chatterText == null) throw new DocuSignException(Label.UndefinedChatterText);
		ValidationResult vr = validate(chatterText);
		if (!vr.isValid) {
			throw new ValidationException(Label.InvalidChatterText, vr);
		}

		ChatterSettings__c settings = ChatterSettings__c.getOrgDefaults();
		settings.EnvelopeSent__c = chatterText.envelopeSent;
		settings.EnvelopeDelivered__c = chatterText.envelopeDelivered;
		settings.EnvelopeCompleted__c = chatterText.envelopeCompleted;
		settings.EnvelopeDeclined__c = chatterText.envelopeDeclined;
		settings.EnvelopeVoided__c = chatterText.envelopeVoided;
		settings.RecipientSent__c = chatterText.recipientSent;
		settings.RecipientDelivered__c = chatterText.recipientDelivered;
		settings.RecipientCompleted__c = chatterText.recipientCompleted;
		settings.RecipientSigned__c = chatterText.recipientSigned;
		settings.RecipientDeclined__c = chatterText.recipientDeclined;
		upsert settings;
	}

	public static List<Localization.ChatterSettings> getChatterSettings() {
		final List<Localization.ChatterSettings> settings = new List<Localization.ChatterSettings> {
			new Localization.ChatterSettings(
				Localization.CURRENT,
				Label.CurrentChatterLanguageSettings,
				Localization.getChatterText())
		};
		for (String language : getAllLanguages()) {
			settings.add(new Localization.ChatterSettings(
				language,
				getLabel(language),
				getDefaultChatterText(language)
			));
		}
		return settings;
	}

	@TestVisible
	private static ValidationResult validate(final Recipient.EmailSettings settings) {
		ValidationResult result = new ValidationResult();
		if (settings != null
			&& (String.isBlank(settings.language) || !LANGUAGE_TO_LABEL.containsKey(settings.language))) {

			result.add(Label.UnrecognizedLanguageCode);
		}
		if (settings == null || String.isBlank(settings.subject) || String.isBlank(settings.message)) {
			result.add(Label.AllValuesMustNotBeBlank);
		}
		return result;
	}

	@TestVisible
	private static ValidationResult validate(final ChatterText chatterText) {
		ValidationResult result = new ValidationResult();
		if (chatterText == null || String.isBlank(chatterText.envelopeCompleted)
			|| String.isBlank(chatterText.envelopeDeclined) || String.isBlank(chatterText.envelopeDelivered)
			|| String.isBlank(chatterText.envelopeSent) || String.isBlank(chatterText.envelopeVoided)
			|| String.isBlank(chatterText.recipientCompleted) || String.isBlank(chatterText.recipientDeclined)
			|| String.isBlank(chatterText.recipientDelivered) || String.isBlank(chatterText.recipientSent)
			|| String.isBlank(chatterText.recipientSigned)) {

			result.add(Label.AllValuesMustNotBeBlank);
		}
		return result;
	}
}
