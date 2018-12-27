public with sharing class TemplateAPI extends ESignatureAPI {

	private static TemplateAPI self = null;
	private final Map<UUID, Template> templateMap;

	@TestVisible
	private TemplateAPI(final Credentials apiCredentials) {
		super(apiCredentials);

		this.templateMap = new Map<UUID, Template>();
	}

	public static TemplateAPI getInstance() {
		if (self == null) {
			self = new TemplateAPI(Credentials.getInstance());
		}
		return self;
	}

	// Serialization objects for templates
	@TestVisible
	private class ListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public CustomField toExternalForm() {
			return CustomField.newListField(name, value, listItems, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class TextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public CustomField toExternalForm() {
			return CustomField.newTextField(name, value, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class CustomFields {
		public List<TextCustomField> textCustomFields;
		public List<ListCustomField> listCustomFields;

		public List<CustomField> toExternalForm() {
			final List<CustomField> cfs = new List<CustomField>();

			if (this.textCustomFields != null) {
				for (TextCustomField cf : this.textCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			if (this.listCustomFields != null) {
				for (ListCustomField cf : listCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			return cfs;
		}
	}

	@TestVisible
	private class TemplateId {
		public String templateId;
		public String name;
		public String lastModified;
	}

	private static String nullIfBlank(final String s) {
		return String.isBlank(s) ? null : s;
	}

	@TestVisible
	private class APIPhoneAuthentication {
		public List<String> senderProvidedNumbers;
	}

	@TestVisible
	private class APIEmailSettings {
		public String emailSubject;
		public String emailBody;
		public String supportedLanguage;

		public Recipient.EmailSettings toExternalForm() {
			return new Recipient.EmailSettings(
				this.supportedLanguage,
				Localization.getLabel(this.supportedLanguage),
				this.emailSubject,
				this.emailBody);
		}
	}

	@TestVisible
	private class APIRecipient {
		public String name;
		public String email;
		public String roleName;
		public String routingOrder;
		public String signingGroupId;
		public String signingGroupName;
		public String hostEmail;
		public String hostName;
		public String signerEmail;
		public String signerName;
		public String accessCode;
		public String requireIdLookup;
		public TemplateAPI.APIPhoneAuthentication phoneAuthentication;
		public String note;
		public String templateLocked;
		public String templateRequired;
		public APIEmailSettings emailNotification;

		private Recipient.Authentication getAuthentication() {
			if (String.isBlank(accessCode)
				&& (this.phoneAuthentication == null
				|| Collection.isEmpty(this.phoneAuthentication.senderProvidedNumbers))) {

				return null;
			}

			return new Recipient.Authentication(
				nullIfBlank(this.accessCode),
				this.requireIdLookup == 'true',
				this.phoneAuthentication == null ? null : this.phoneAuthentication.senderProvidedNumbers);
		}

		private Boolean getSignNow() {
			String currentUserEmail = UserInfo.getUserEmail();
			return this.routingOrder == '1' && currentUserEmail == this.email || currentUserEmail == this.hostEmail;
		}

		public Recipient toExternalForm(final String type) {
			Boolean inPersonSigner = type == Recipient.TYPE_IN_PERSON_SIGNER;
			Integer routingOrder = StringUtils.parseInteger(this.routingOrder, null);
			return new Recipient(
				null, // id
				type,
				routingOrder == null ? 1 : routingOrder,
				routingOrder,
				String.isBlank(this.roleName) ? null : new Recipient.Role(this.roleName),
				inPersonSigner ? nullIfBlank(this.signerName) : nullIfBlank(this.name),
				inPersonSigner ? nullIfBlank(this.signerEmail) : nullIfBlank(this.email),
				String.isBlank(this.signingGroupId) ? null :
					new SigningGroup(Integer.valueOf(this.signingGroupId), this.signingGroupName),
				null, // phone
				getAuthentication(),
				nullIfBlank(this.note),
				this.emailNotification == null ? null : this.emailNotification.toExternalForm(),
				nullIfBlank(this.hostName),
				nullIfBlank(this.hostEmail),
				getSignNow(),
				null, // source
				this.templateLocked == 'true',
				this.templateRequired == 'true');
		}
	}

	@TestVisible
	private class APIRecipients {
		public List<APIRecipient> agents;
		public List<APIRecipient> carbonCopies;
		public List<APIRecipient> certifiedDeliveries;
		public List<APIRecipient> editors;
		public List<APIRecipient> inPersonSigners;
		public List<APIRecipient> intermediaries;
		public List<APIRecipient> signers;

		public List<Recipient> toExternalForm() {
			List<Recipient> result = new List<Recipient>();

			if (Collection.isNotEmpty(this.agents)) {
				for (APIRecipient r : this.agents) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_AGENT));
				}
			}

			if (Collection.isNotEmpty(this.carbonCopies)) {
				for (APIRecipient r : this.carbonCopies) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_CARBON_COPY));
				}
			}

			if (Collection.isNotEmpty(this.certifiedDeliveries)) {
				for (APIRecipient r : this.certifiedDeliveries) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_CERTIFIED_DELIVERY));
				}
			}

			if (Collection.isNotEmpty(this.editors)) {
				for (APIRecipient r : this.editors) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_EDITOR));
				}
			}

			if (Collection.isNotEmpty(this.inPersonSigners)) {
				for (APIRecipient r : this.inPersonSigners) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_IN_PERSON_SIGNER));
				}
			}

			if (Collection.isNotEmpty(this.intermediaries)) {
				for (APIRecipient r : this.intermediaries) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_INTERMEDIARY));
				}
			}

			if (Collection.isNotEmpty(this.signers)) {
				for (APIRecipient r : this.signers) {
					if (r != null) result.add(r.toExternalForm(Recipient.TYPE_SIGNER));
				}
			}

			// Ensure ordinal sequence is ascending and sequential
			result.sort(); // sorts by routing order
			for (Integer i = 0; i < result.size(); i++) {
				result[i] = result[i].withSequence(i + 1);
			}
			return result;
		}
	}

	@TestVisible
	private class APIReminders {
		public String reminderEnabled;
		public String reminderDelay;
		public String reminderFrequency;
	}

	@TestVisible
	private class APIExpirations {
		public String expireEnabled;
		public String expireAfter;
		public String expireWarn;
	}

	@TestVisible
	private class APINotification {
		public APIReminders reminders;
		public APIExpirations expirations;

		public Notifications toExternalForm() {
			Boolean isRemindDefined = this.reminders != null;
			Boolean isExpireDefined = this.expirations != null;
			return new Notifications(
				isRemindDefined ? Boolean.valueOf(this.reminders.reminderEnabled) : false,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderDelay) : null,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderFrequency) : null,
				isExpireDefined ? Boolean.valueOf(this.expirations.expireEnabled) : false,
				isExpireDefined ? Integer.valueOf(this.expirations.expireAfter) : null,
				isExpireDefined ? Integer.valueOf(this.expirations.expireWarn) : null,
				EnvelopeSettings.getInstance().isChatterEnabled);
		}
	}

	@TestVisible
	private class APITemplate {
		public TemplateId envelopeTemplateDefinition;
		public CustomFields customFields;
		public APINotification notification;
		public String emailSubject;
		public String emailBlurb;
		public APIRecipients recipients;

		public Template toExternalForm() {
			return new Template(
				this.envelopeTemplateDefinition == null ? null : UUID.parse(envelopeTemplateDefinition.templateId),
				this.envelopeTemplateDefinition == null ? null : nullIfBlank(envelopeTemplateDefinition.name),
				this.customFields == null ? new List<CustomField>() : this.customFields.toExternalForm(),
				this.notification == null ? null : this.notification.toExternalForm(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				this.recipients == null ? new List<Recipient>() : this.recipients.toExternalForm(),
				this.envelopeTemplateDefinition == null
					? null : StringUtils.parseDatetime(this.envelopeTemplateDefinition.lastModified));
		}
	}

	public Template getTemplate(final UUID templateId) {
		return getTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Template getTemplate(final UUID templateId, final Integer timeout) {
		if (templateMap.containsKey(templateId)) return templateMap.get(templateId);

		final RestAPI.Response response = this.get(
			new List<Object> { 'templates', templateId },
			new QueryString('include', 'custom_fields,notifications,recipients'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template: ' + response.error.toString());
			throw new APIException(response.error);
		}

		Template template = ((TemplateAPI.APITemplate)JSON.deserialize(response.body,
			TemplateAPI.APITemplate.class)).toExternalForm();
		templateMap.put(template.id, template);
		return template;
	}

	@TestVisible
	private class APITemplateListResult {
		public String templateId;
		public String name;
		public CustomFields customFields;
		public APINotification notification;
		public String emailSubject;
		public String emailBlurb;
		public APIRecipients recipients;
		public String lastModified;

		public Template toExternalForm() {
			return new Template(
				UUID.parse(this.templateId),
				nullIfBlank(this.name),
				this.customFields == null ? new List<CustomField>() : this.customFields.toExternalForm(),
				this.notification == null ? null : this.notification.toExternalForm(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				this.recipients == null ? new List<Recipient>() : this.recipients.toExternalForm(),
				StringUtils.parseDatetime(this.lastModified));
		}
	}

	@TestVisible
	private class Templates {
		public String resultSetSize;
		public String startPosition;
		public String endPosition;
		public String totalSetSize;
		public List<APITemplateListResult> envelopeTemplates;

		public List<Template> toExternalForm() {
			final List<Template> templates = new List<Template>();
			if (this.envelopeTemplates != null) {
				for (APITemplateListResult t : this.envelopeTemplates) {
					templates.add(t.toExternalForm());
				}
			}
			return templates;
		}
	}

	public List<Template> getTemplates() {
		return this.getTemplates(RestAPI.defaultTimeout);
	}

	// TODO: Refactor to only search templates by partial name.
	// TODO: This API supports paging, but unclear what is default or max limit.
	public List<Template> getTemplates(final Integer timeout) {
		final RestAPI.Response response = this.get(
			'templates',
			new QueryString(new Map<String, String> {
				'include' => 'custom_fields,shared_template_folders,notifications,recipients',
				'order_by' => 'name',
				'order' => 'asc'
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get templates: ' + response.error.toString());
			throw new APIException(response.error);
		}

		List<Template> templates = ((TemplateAPI.Templates)JSON.deserialize(response.body,
			TemplateAPI.Templates.class)).toExternalForm();
		for (Template t : templates) {
			templateMap.put(t.id, t);
		}
		return templates;
	}
}
