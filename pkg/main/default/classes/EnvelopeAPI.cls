/*
	Inner classes should ideally be protected so that derived classes can reuse the implementation without leaking
	API implementation details. Unfortunately Apex doesn't allow this so some of the classes must be public to reuse
	code or we have to structure our code less efficiently. In this case, TemplateAPI was merged here because it shared
	much of the request/response structure as this.
 */
public with sharing class EnvelopeAPI extends ESignatureAPI {

	private static EnvelopeAPI self = null;
	private static final String ACCOUNT_LACKS_PERMISSIONS = 'ACCOUNT_LACKS_PERMISSIONS';
	private static final String RECIPIENT_NOT_IN_SEQUENCE = 'RECIPIENT_NOT_IN_SEQUENCE';
	private static final String UNKNOWN_ENVELOPE_RECIPIENT = 'UNKNOWN_ENVELOPE_RECIPIENT';
	private static final String USER_LACKS_PERMISSIONS = 'USER_LACKS_PERMISSIONS';
	private static final List<DocumentResolver> DOCUMENT_RESOLVERS = new List<DocumentResolver>();
	private static final Set<String> HTML_EXTENSIONS = new Set<String> { 'htm', 'html', 'adf' };
	private final Map<UUID, Template> templateMap;

	static {
		String rs = AccountSettings__c.getOrgDefaults().DocumentResolvers__c;
		if (String.isNotBlank(rs)) {
			for (String r : rs.split(',')) {
				try {
					DOCUMENT_RESOLVERS.add((DocumentResolver)Type.forName(r.trim()).newInstance());
				} catch (Exception ex) {
					LoggerService.getInstance().exception(ex, 'Invalid document resolver: ' + r.trim());
					throw new DocuSignException(String.format(Label.InvalidDocumentResolver_1, new List<String> {
						r.trim()
					}));
				}
			}
		}
	}

	private EnvelopeAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(baseUrl, apiVersion, accountId);

		this.templateMap = new Map<UUID, Template>();
	}

	public static EnvelopeAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new EnvelopeAPI(
				c.environment.eSignatureBaseUrl,
				'v2',
				c.account.id);
		}
		return self;
	}

	@TestVisible
	override protected APIError getError(final HttpResponse response) {
		return getError(super.getError(response));
	}

	private static APIError getError(final APIError error) {
		APIError e = error;
		if (error != APIError.none && error instanceof ESignatureAPI.Error) {
			ESignatureAPI.Error dse = (ESignatureAPI.Error)error;
			if (dse.docuSignCode == ACCOUNT_LACKS_PERMISSIONS) {
				e = new APIError(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, dse.description);
			} else if (dse.docuSignCode == RECIPIENT_NOT_IN_SEQUENCE) {
				e = new APIError(APIErrorCode.INVALID_RECIPIENT_SEQUENCE, Label.InvalidRecipientSequence);
			} else if (dse.docuSignCode == UNKNOWN_ENVELOPE_RECIPIENT) {
				e = new APIError(APIErrorCode.UNKNOWN_RECIPIENT, Label.UnknownEnvelopeRecipient);
			} else if (dse.docuSignCode == USER_LACKS_PERMISSIONS) {
				e = new APIError(APIErrorCode.UNAUTHORIZED, Label.UserNotAuthorizedForEnvelope);
			}
		}
		return e;
	}

	// get*View Url serialization objects
	@TestVisible
	private class APIViewRequest {
		public String authenticationMethod;
		public String email;
		public String returnUrl;
		public String userName;
		public String recipientId;
		public String envelopeId;
		public String clientUserId;
		public Boolean suppressNavigation;

		public APIViewRequest(
			final UUID envelopeId,
			final Url returnUrl) {

			this.authenticationMethod = null;
			this.email = null;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = null;
			this.recipientId = null;
			this.envelopeId = UUID.toString(envelopeId);
			this.suppressNavigation = true;
		}

		public APIViewRequest(final Url returnUrl) {
			this.authenticationMethod = null;
			this.email = null;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = null;
			this.recipientId = null;
			this.envelopeId = null;
			this.suppressNavigation = true;
		}

		public APIViewRequest(
			final String authenticationMethod,
			final String email,
			final Url returnUrl,
			final String userName,
			final Integer recipientId) {

			this.authenticationMethod = authenticationMethod;
			this.email = email;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = userName;
			this.recipientId = String.valueOf(recipientId);
			this.envelopeId = null;
			this.suppressNavigation = true;
		}

		//Embedded Recipient constructor
		public APIViewRequest(
			final String authenticationMethod,
			final String clientUserId,
			final Url returnUrl,
			final String userName,
			final String email) {

			this.authenticationMethod = authenticationMethod;
			this.clientUserId = clientUserId;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = userName;
			this.email = email;
		}
	}

	@TestVisible
	private class APIViewResponse {
		public String url;
	}

	public Url getSenderViewUrl(
		final UUID envelopeId,
		final Url returnUrl) {

		return this.getSenderViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getSenderViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'sender' },
			JSON.serialize(new APIViewRequest(returnUrl), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get sender view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	public Url getRecipientViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final String email,
		final String userName,
		final Integer recipientId) {

		return this.getRecipientViewUrl(envelopeId, returnUrl, email, userName, recipientId, RestAPI.defaultTimeout);
	}

	public Url getRecipientViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final String email,
		final String userName,
		final Integer recipientId,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'recipient' },
			JSON.serialize(new APIViewRequest('email', email, returnUrl, userName, recipientId), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get recipient view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	//Embedded Recipient view request
	public Url getEmbeddedRecipientViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final String email,
		final String userName) {

		return this.getEmbeddedRecipientViewUrl(envelopeId, returnUrl, email, userName, RestAPI.defaultTimeout);
	}

	public Url getEmbeddedRecipientViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final String email,
		final String userName,
		final Integer timeout) {

		String clientUserId = UserInfo.getUserId();
		RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'recipient' },
			JSON.serialize(new APIViewRequest('email', clientUserId, returnUrl, userName, email), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get recipient view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	public Url getConsoleViewUrl(
		final UUID envelopeId,
		final Url returnUrl) {

		return this.getConsoleViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getConsoleViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'views', 'console' },
			JSON.serialize(new APIViewRequest(envelopeId, returnUrl), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get console view: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	public Url getCorrectViewUrl(
		final UUID envelopeId,
		final Url returnUrl) {

		return this.getCorrectViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getCorrectViewUrl(
		final UUID envelopeId,
		final Url returnUrl,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'correct' },
			JSON.serialize(new APIViewRequest(returnUrl), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get correct view: ' + response.error.toString());
			APIError error; // TODO: Use error codes instead of message parsing.
			if (response.error.description.contains('Only envelopes in the \'Sent\' or \'Delivered\' states may be corrected.')) {
				error = new APIError(response.error.code, Label.InvalidCorrectionState);
			} else if (response.error.description.contains('envelope is locked')) {
				error = new APIError(response.error.code, Label.EnvelopeLockedCorrectionInProgress);
			} else if (response.error.description.contains('This user is not the sender of the envelope.')) {
				error = new APIError(response.error.code, Label.NotEnvelopeOwner);
			} else if (response.error.description.contains('The envelope specified either does not exist or you have no rights to it')) {
				error = new APIError(response.error.code, Label.EnvelopeNotFoundOrUnauthorized);
			} else {
				error = response.error;
			}
			throw new APIException(error);
		}

		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	public Url getTemplateEditUrl(
		final UUID templateId,
		final Url returnUrl) {

		return this.getTemplateEditUrl(templateId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getTemplateEditUrl(
		final UUID templateId,
		final Url returnUrl,
		final Integer timeout) {

		if (UUID.isEmpty(templateId)) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.post(
			new List<Object> { 'templates', templateId, 'views', 'edit' },
			JSON.serialize(new APIViewRequest(returnUrl), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template edit view: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	public Boolean resendEnvelope(final UUID envelopeId) {
		return this.resendEnvelope(envelopeId, RestAPI.defaultTimeout);
	}

	public Boolean resendEnvelope(
		final UUID envelopeId,
		final Integer timeout) {

		Boolean isResent = false;
		RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId },
			new QueryString('resend_envelope', 'true'),
			'{}',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to resend envelope: ' + response.error.toString());
			throw new APIException(response.error);
		} else {
			isResent = true;
		}
		return isResent;
	}

	// Serialization objects for resendRecipients
	@TestVisible
	private class APIResendResult {
		public ESignatureAPI.ErrorDetails errorDetails;
		public String recipientId;

		public Recipient.ResendResult toResendResult(final Recipient r) {
			return new Recipient.ResendResult(
				StringUtils.parseInteger(this.recipientId, null),
				r == null ? null : r.email,
				r == null ? null : r.routingOrder,
				this.errorDetails == null ? null : getError(this.errorDetails.toExternalForm()));
		}
	}

	@TestVisible
	private class APIResendResults {
		public List<APIResendResult> recipientUpdateResults;

		public List<Recipient.ResendResult> toResendResults(final Map<String, Recipient> recipients) {
			List<Recipient.ResendResult> result = new List<Recipient.ResendResult>();
			if (this.recipientUpdateResults != null) {
				for (APIResendResult rr : this.recipientUpdateResults) {
					result.add(rr.toResendResult(recipients.get(rr.recipientId)));
				}
			}
			return result;
		}
	}

	public List<Recipient.ResendResult> resendRecipients(
		final UUID envelopeId,
		final List<Recipient> recipients) {

		return this.resendRecipients(envelopeId, recipients, RestAPI.defaultTimeout);
	}

	public List<Recipient.ResendResult> resendRecipients(
		final UUID envelopeId,
		final List<Recipient> recipients,
		final Integer timeout) {

		if (envelopeId == null) throw new DocuSignException(Label.InvalidEnvelope);
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.AtLeastOneRecipientIsRequired);

		RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId, 'recipients' },
			new QueryString('resend_envelope', 'true'),
			JSON.serialize(new APIRecipients(recipients, null, false)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to resend envelope: ' + response.error.toString());
			throw new APIException(response.error);
		}

		Map<String, Recipient> rMap = new Map<String, Recipient>();
		for (Recipient r : recipients) {
			rMap.put(String.valueOf(r.sequence), r);
		}
		return ((APIResendResults)JSON.deserialize(response.body, APIResendResults.class)).toResendResults(rMap);
	}

	// Serialization objects for envelopes and templates
	@TestVisible
	private class APIListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public APIListCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
				this.listItems = cf.items;
			}
		}

		public CustomField toCustomField() {
			return CustomField.newListField(
				this.name,
				nullIfBlank(this.value),
				this.listItems,
				StringUtils.parseBoolean(this.required),
				StringUtils.parseBoolean(this.show));
		}
	}

	@TestVisible
	private class APITextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public APITextCustomField(
			final String name,
			final String value,
			final Boolean required,
			final Boolean show) {

			this.name = name;
			this.value = value;
			this.required = String.valueOf(required);
			this.show = String.valueOf(show);
		}

		public APITextCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
			}
		}

		public CustomField toCustomField() {
			return CustomField.newTextField(
				this.name,
				nullIfBlank(this.value),
				StringUtils.parseBoolean(this.required),
				StringUtils.parseBoolean(this.show));
		}
	}

	@TestVisible
	private class APICustomFields {
		public List<APITextCustomField> textCustomFields;
		public List<APIListCustomField> listCustomFields;

		public APICustomFields(
			final List<APITextCustomField> textCustomFields,
			final List<APIListCustomField> listCustomFields) {

			this.textCustomFields = textCustomFields;
			this.listCustomFields = listCustomFields;
		}

		public List<CustomField> toCustomFields() {
			final List<CustomField> cfs = new List<CustomField>();

			if (this.textCustomFields != null) {
				for (APITextCustomField cf : this.textCustomFields) {
					cfs.add(cf.toCustomField());
				}
			}

			if (this.listCustomFields != null) {
				for (APIListCustomField cf : listCustomFields) {
					cfs.add(cf.toCustomField());
				}
			}

			return cfs;
		}
	}

	// Serialization objects for update in-person signer
	@TestVisible
	private class APIInPersonSigner {
		public String hostName;
		public String hostEmail;
		public String signerEmail;
		public String recipientId;

		public APIInPersonSigner(final String signerEmail) {
			this.recipientId = '1';
			this.hostName = UserInfo.getName();
			this.hostEmail = UserInfo.getUserEmail();
			this.signerEmail = signerEmail;
		}
	}

	@TestVisible
	private class APIInPersonSigners {
		public List<APIInPersonSigner> inPersonSigners { get; private set; }

		public APIInPersonSigners(final String signerEmail) {
			this.inPersonSigners = new List<APIInPersonSigner> { new APIInPersonSigner(signerEmail) };
		}
	}

	// Special case of update recipients API assuming current user is host, and the first recipient is in-person.
	public Boolean updateInPersonSigner(
		final UUID envelopeId,
		final String signerEmail) {

		return updateInPersonSigner(envelopeId, signerEmail, RestAPI.defaultTimeout);
	}

	public Boolean updateInPersonSigner(
		final UUID envelopeId,
		final String signerEmail,
		final Integer timeout) {

		RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId, 'recipients' },
			JSON.serialize(new APIInPersonSigners(signerEmail)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update in-person signer: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return true;
	}

	// Serialization objects for createEnvelope
	@TestVisible
	private class APIExpirations {
		public String expireEnabled;
		public String expireAfter;
		public String expireWarn;

		public APIExpirations(
			final Boolean expires,
			final Integer expireAfterDays,
			final Integer expireWarnDays) {

			this.expireEnabled = String.valueOf(expires);
			this.expireAfter = String.valueOf(expireAfterDays);
			this.expireWarn = String.valueOf(expireWarnDays);
		}
	}

	@TestVisible
	private class APIReminders {
		public String reminderEnabled;
		public String reminderDelay;
		public String reminderFrequency;

		public APIReminders(
			final Boolean remind,
			final Integer remindAfterDays,
			final Integer remindFrequencyDays) {

			this.reminderEnabled = String.valueOf(remind);
			this.reminderDelay = String.valueOf(remindAfterDays);
			this.reminderFrequency = String.valueOf(remindFrequencyDays);
		}
	}

	@TestVisible
	private class APINotifications {
		public APIReminders reminders;
		public APIExpirations expirations;
		public String useAccountDefaults;

		public APINotifications(final Notifications notifications) {
			if (notifications == null) {
				this.useAccountDefaults = 'true';
			} else {
				this.reminders = new APIReminders(
					notifications.remind,
					notifications.remindAfterDays,
					notifications.remindFrequencyDays);
				this.expirations = new APIExpirations(
					notifications.expires,
					notifications.expireAfterDays,
					notifications.expireWarnDays);
				this.useAccountDefaults = 'false';
			}
		}

		public Notifications toNotifications() {
			Boolean isRemindDefined = this.reminders != null;
			Boolean isExpireDefined = this.expirations != null;
			return new Notifications(
				isRemindDefined ? Boolean.valueOf(this.reminders.reminderEnabled) : false,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderDelay) : null,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderFrequency) : null,
				isExpireDefined ? Boolean.valueOf(this.expirations.expireEnabled) : false,
				isExpireDefined ? Integer.valueOf(this.expirations.expireAfter) : null,
				isExpireDefined ? Integer.valueOf(this.expirations.expireWarn) : null);
		}
	}

	@TestVisible
	private class APIHtmlDefinition {
		public String source;

		public APIHtmlDefinition(final String source) {
			this.source = source;
		}
	}

	private static Boolean isHtml(final Document doc) {
		return doc != null
			&& String.isNotBlank(doc.extension)
			&& HTML_EXTENSIONS.contains(doc.extension.toLowerCase());
	}

	@TestVisible
	private class APIDocument {
		public String documentId;
		public String name;
		public String fileExtension;
		public String documentBase64;
		public APIHtmlDefinition htmlDefinition;
		public String templateLocked;
		public String templateRequired;

		public APIDocument(
			final Document doc,
			final Blob content) {

			if (doc != null && doc.type != Document.TYPE_TEMPLATE) {
				this.documentId = String.valueOf(doc.sequence);
				this.name = doc.name;
				this.fileExtension = doc.extension;
				if (content != null) {
					if (isHtml(doc)) {
						this.htmlDefinition = new APIHtmlDefinition(content.toString());
					} else {
						this.documentBase64 = EncodingUtil.base64Encode(content);
					}
				}
				this.templateLocked = String.valueOf(doc.readOnly);
				this.templateRequired = String.valueOf(doc.required);
			}
		}

		public Document toDocument() {
			return new Document(
				null,
				Document.TYPE_FILE,
				Integer.valueOf(this.documentId),
				this.name,
				nullIfBlank(this.fileExtension),
				null,
				StringUtils.parseBoolean(this.templateLocked),
				StringUtils.parseBoolean(this.templateRequired));
		}
	}

	@TestVisible
	private class APISmsAuthentication {
		public List<String> senderProvidedNumbers;

		public APISmsAuthentication(final List<String> ns) {
			this.senderProvidedNumbers = ns;
		}
	}

	@TestVisible
	private class APIEmailSettings {
		public String supportedLanguage;
		public String emailSubject;
		public String emailBody;

		public APIEmailSettings(final Recipient.EmailSettings es) {
			if (es != null) {
				this.supportedLanguage = es.language;
				this.emailSubject = es.subject;
				this.emailBody = es.message;
			}
		}
	}

	@TestVisible
	private class APIRecipient {
		public String recipientId;
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
		public List<String> customFields;
		public APIEmailSettings emailNotification;
		public String accessCode;
		public String requireIdLookup;
		public String idCheckConfigurationName;
		public APISmsAuthentication smsAuthentication;
		public String note;
		public APITabs tabs;
		public String status;
		public String deliveredDateTime;
		public String signedDateTime;
		public String declinedDateTime;
		public String declinedReason;
		public String clientUserId;
		public String templateLocked;
		public String templateRequired;

		public APIRecipient(
			final Recipient r,
			final String documentId,
			final Boolean includeDefaultAnchorTags) {

			if (r != null) {
				this.recipientId = String.isBlank(r.envelopeRecipientId)
					? String.valueOf(r.sequence) : r.envelopeRecipientId;
				if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
					this.signerName = r.name;
					this.signerEmail = r.email == r.hostEmail ? null : r.email;
					this.hostName = r.hostName;
					this.hostEmail = r.hostEmail;
				} else {
					this.name = r.name;
					this.email = r.email;
				}
				// API requires a defined value for roleName when templates are used. Empty strings are OK.
				this.roleName = r.role == null || String.isBlank(r.role.name) ? '' : r.role.name;
				this.routingOrder = r.routingOrder == null ? '' : String.valueOf(r.routingOrder);
				this.signingGroupId = r.isSigningGroup ? String.valueOf(r.signingGroup.id) : null;
				this.customFields = getRecipientCustomFields(r);
				this.emailNotification = r.emailSettings == null
					|| (String.isBlank(r.emailSettings.subject) && String.isBlank(r.emailSettings.message))
					? null : new APIEmailSettings(r.emailSettings);
				if (r.authentication != null) {
					this.accessCode = r.authentication.accessCode;
					this.requireIdLookup = String.valueOf(r.authentication.idCheckRequired);
					if (Collection.isNotEmpty(r.authentication.smsPhoneNumbers)) {
						this.requireIdLookup = 'true';
						this.idCheckConfigurationName = 'SMS Auth $';
						this.smsAuthentication = new APISmsAuthentication(r.authentication.smsPhoneNumbers);
					}
				}
				this.note = r.note;

				// Only add default anchor tags if role is defined and has a valid (> 0) value.
				this.tabs = new APITabs(
					documentId,
					this.recipientId,
					r.tabs,
					includeDefaultAnchorTags
						&& String.isBlank(r.envelopeRecipientId)
						&& r.role != null
						&& r.role.hasValue,
					r.role == null ? null : r.role.value);

				//setting the clientUserId property for embedded recipients
				//setting this to the Salesforce user id of the recipient
				//this will be set only for embedded recipients. If this property is set for other recipients the
				//envelope is not sent
				if (r.type == Recipient.TYPE_EMBEDDED_SIGNER) {
					this.clientUserId = Entity.isValid(r.source) ? r.source.id : null;
				}
				this.templateLocked = String.valueOf(r.readOnly);
				this.templateRequired = String.valueOf(r.required);
			}
		}

		public Recipient toRecipient(final String type) {
			return new Recipient(
				null,
				nullIfBlank(this.recipientId),
				type,
				StringUtils.parseInteger(this.recipientId),
				StringUtils.parseInteger(this.routingOrder),
				String.isBlank(this.roleName) ? null : new Recipient.Role(this.roleName),
				type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.signerName) : nullIfBlank(this.name),
				type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.signerEmail) : nullIfBlank(this.email),
				String.isBlank(this.signingGroupId) ? null
					: new SigningGroup(
					Integer.valueOf(this.signingGroupId),
					nullIfBlank(this.signingGroupName)),
				null,
				String.isBlank(this.accessCode) && !StringUtils.parseBoolean(this.requireIdLookup) ? null
					: new Recipient.Authentication(
					nullIfBlank(this.accessCode),
					StringUtils.parseBoolean(this.requireIdLookup),
					this.smsAuthentication == null ? null : this.smsAuthentication.senderProvidedNumbers),
				nullIfBlank(this.note),
				this.emailNotification == null ? null : new Recipient.EmailSettings(
					nullIfBlank(this.emailNotification.supportedLanguage),
					Localization.getLabel(this.emailNotification.supportedLanguage),
					nullIfBlank(this.emailNotification.emailSubject),
					nullIfBlank(this.emailNotification.emailBody)),
				type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.hostName) : null,
				type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.hostEmail) : null,
				false,
				this.tabs == null ? null : this.tabs.toTabs(),
				null,
				StringUtils.parseBoolean(this.templateLocked),
				StringUtils.parseBoolean(this.templateRequired));
		}

		public Recipient.Status toStatus(final String type) {
			Boolean inPersonSigner = type == Recipient.TYPE_IN_PERSON_SIGNER;
			return new Recipient.Status(
				null, // id
				null, // source
				type,
				null,
				this.status,
				inPersonSigner ? nullIfBlank(this.signerName) : nullIfBlank(this.name),
				inPersonSigner ? nullIfBlank(this.signerEmail) : nullIfBlank(this.email),
				String.isBlank(this.routingOrder) ? null : Integer.valueOf(this.routingOrder),
				StringUtils.parseDatetime(this.deliveredDateTime),
				String.isNotBlank(this.declinedDateTime) ? StringUtils.parseDatetime(this.declinedDateTime)
					: StringUtils.parseDatetime(this.signedDateTime),
				nullIfBlank(this.declinedReason),
				Datetime.now());
		}
	}

	@TestVisible
	private static List<String> getRecipientCustomFields(final Recipient r) {
		List<String> customFields = null;
		if (r != null && Entity.isValid(r.source)) {
			String cf = CustomField.forRecipientSource(r.source.id);
			if (String.isNotBlank(cf)) {
				customFields = new List<String> { cf };
			}
		}
		return customFields;
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
		public List<APIRecipient> seals;
		public List<APIRecipient> witnesses;

		public APIRecipients(
			final List<Recipient> rs,
			final String documentId,
			final Boolean includeDefaultAnchorTags) {

			if (rs != null) {
				this.agents = new List<APIRecipient>();
				this.carbonCopies = new List<APIRecipient>();
				this.certifiedDeliveries = new List<APIRecipient>();
				this.editors = new List<APIRecipient>();
				this.inPersonSigners = new List<APIRecipient>();
				this.intermediaries = new List<APIRecipient>();
				this.seals = new List<APIRecipient>();
				this.signers = new List<APIRecipient>();
				this.witnesses = new List<APIRecipient>();
				for (Recipient r : rs) {
					if (r.type == Recipient.TYPE_AGENT) {
						this.agents.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_CARBON_COPY) {
						this.carbonCopies.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_CERTIFIED_DELIVERY) {
						this.certifiedDeliveries.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_EDITOR) {
						this.editors.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_INTERMEDIARY) {
						this.intermediaries.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
						this.inPersonSigners.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_SEAL) {
						this.seals.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else if (r.type == Recipient.TYPE_WITNESS) {
						this.witnesses.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					} else { // Recipient.TYPE_SIGNER and Recipient.TYPE_EMBEDDED_SIGNER
						this.signers.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					}
				}
			}
		}

		public List<Recipient> toRecipients() {
			List<Recipient> result = new List<Recipient>();
			if (this.agents != null) {
				for (EnvelopeAPI.APIRecipient r : this.agents) {
					result.add(r.toRecipient(Recipient.TYPE_AGENT));
				}
			}
			if (this.carbonCopies != null) {
				for (EnvelopeAPI.APIRecipient r : this.carbonCopies) {
					result.add(r.toRecipient(Recipient.TYPE_CARBON_COPY));
				}
			}
			if (this.certifiedDeliveries != null) {
				for (EnvelopeAPI.APIRecipient r : this.certifiedDeliveries) {
					result.add(r.toRecipient(Recipient.TYPE_CERTIFIED_DELIVERY));
				}
			}
			if (this.editors != null) {
				for (EnvelopeAPI.APIRecipient r : this.editors) {
					result.add(r.toRecipient(Recipient.TYPE_EDITOR));
				}
			}
			if (this.intermediaries != null) {
				for (EnvelopeAPI.APIRecipient r : this.intermediaries) {
					result.add(r.toRecipient(Recipient.TYPE_INTERMEDIARY));
				}
			}
			if (this.inPersonSigners != null) {
				for (EnvelopeAPI.APIRecipient r : this.inPersonSigners) {
					result.add(r.toRecipient(Recipient.TYPE_IN_PERSON_SIGNER));
				}
			}
			if (this.signers != null) {
				for (EnvelopeAPI.APIRecipient r : this.signers) {
					result.add(r.toRecipient(Recipient.TYPE_SIGNER));
				}
			}
			if (this.seals != null) {
				for (EnvelopeAPI.APIRecipient r : this.seals) {
					result.add(r.toRecipient(Recipient.TYPE_SEAL));
				}
			}
			if (this.witnesses != null) {
				for (EnvelopeAPI.APIRecipient r : this.witnesses) {
					result.add(r.toRecipient(Recipient.TYPE_WITNESS));
				}
			}
			result.sort();
			Integer sequence = 0;
			for (Recipient r : result) {
				r = r.withSequence(++sequence);
			}
			return result;
		}

		public List<Recipient.Status> toStatus() {
			List<Recipient.Status> result = new List<Recipient.Status>();
			if (this.agents != null) {
				for (EnvelopeAPI.APIRecipient r : this.agents) {
					result.add(r.toStatus(Recipient.TYPE_AGENT));
				}
			}
			if (this.carbonCopies != null) {
				for (EnvelopeAPI.APIRecipient r : this.carbonCopies) {
					result.add(r.toStatus(Recipient.TYPE_CARBON_COPY));
				}
			}
			if (this.certifiedDeliveries != null) {
				for (EnvelopeAPI.APIRecipient r : this.certifiedDeliveries) {
					result.add(r.toStatus(Recipient.TYPE_CERTIFIED_DELIVERY));
				}
			}
			if (this.editors != null) {
				for (EnvelopeAPI.APIRecipient r : this.editors) {
					result.add(r.toStatus(Recipient.TYPE_EDITOR));
				}
			}
			if (this.intermediaries != null) {
				for (EnvelopeAPI.APIRecipient r : this.intermediaries) {
					result.add(r.toStatus(Recipient.TYPE_INTERMEDIARY));
				}
			}
			if (this.inPersonSigners != null) {
				for (EnvelopeAPI.APIRecipient r : this.inPersonSigners) {
					result.add(r.toStatus(Recipient.TYPE_IN_PERSON_SIGNER));
				}
			}
			if (this.signers != null) {
				for (EnvelopeAPI.APIRecipient r : this.signers) {
					result.add(r.toStatus(Recipient.TYPE_SIGNER));
				}
			}
			if (this.seals != null) {
				for (EnvelopeAPI.APIRecipient r : this.seals) {
					result.add(r.toStatus(Recipient.TYPE_SEAL));
				}
			}
			if (this.witnesses != null) {
				for (EnvelopeAPI.APIRecipient r : this.witnesses) {
					result.add(r.toStatus(Recipient.TYPE_WITNESS));
				}
			}
			result.sort();
			Integer sequence = 0;
			for (Recipient.Status rs : result) {
				rs = rs.withSequence(++sequence);
			}
			return result;
		}

		private List<Tab> getMergeFields(
			final List<APIRecipient> recipients,
			final Boolean writeBackOnly) {

			List<Tab> result = new List<Tab>();
			if (recipients != null) {
				for (APIRecipient r : recipients) {
					if (r != null && r.tabs != null) result.addAll(r.tabs.toMergeFields(writeBackOnly));
				}
			}
			return result;
		}

		public List<Tab> getMergeFields(final Boolean writeBackOnly) {
			List<Tab> result = new List<Tab>();
			result.addAll(getMergeFields(this.agents, writeBackOnly));
			result.addAll(getMergeFields(this.carbonCopies, writeBackOnly));
			result.addAll(getMergeFields(this.certifiedDeliveries, writeBackOnly));
			result.addAll(getMergeFields(this.editors, writeBackOnly));
			result.addAll(getMergeFields(this.inPersonSigners, writeBackOnly));
			result.addAll(getMergeFields(this.intermediaries, writeBackOnly));
			result.addAll(getMergeFields(this.seals, writeBackOnly));
			result.addAll(getMergeFields(this.signers, writeBackOnly));
			result.addAll(getMergeFields(this.witnesses, writeBackOnly));
			return result;
		}
	}

	@TestVisible
	private class APIMergeField {
		public String allowSenderToEdit;
		public String configurationType;
		public String path;
		//public String row; // TODO: Enable merge field rows.
		public String writeBack;

		public APIMergeField(final Tab tab) {
			if (tab != null) {
				this.allowSenderToEdit = String.valueOf(tab.allowSenderToEdit);
				this.configurationType = 'salesforce';
				this.path = tab.path;
				this.writeBack = String.valueOf(tab.writeBack);
			}
		}
	}

	@TestVisible
	private class APITab {
		public String customTabId;
		public String documentId;
		public String recipientId;
		public String name;
		public String tabLabel;
		public String anchorIgnoreIfNotPresent;
		public String anchorString;
		public APIMergeField mergeField;
		public String optional;
		public String value;
		public String selected; // checkbox value

		public APITab(
			final String documentId,
			final String recipientId,
			final Integer roleValue,
			final String name,
			final String anchor,
			final Boolean required) {

			this.documentId = String.valueOf(documentId);
			this.recipientId = String.valueOf(recipientId);
			if (this.documentId == null) {
				this.name = name;
			} else {
				this.name = name + documentId;
			}
			this.tabLabel = '_DAL_' + name;
			this.anchorIgnoreIfNotPresent = 'true';
			if (String.isNotBlank(anchor)) {
				this.anchorString = roleValue != null ? '\\' + anchor + roleValue + '\\' : '\\' + anchor + '\\';
			}
			this.optional = String.valueOf(!required);
		}

		public APITab(
			final String documentId,
			final String recipientId,
			final Tab t) {

			this.documentId = documentId;
			this.recipientId = recipientId;
			if (t != null) {
				if (UUID.isNotEmpty(t.id)) this.customTabId = String.valueOf(t.id);
				this.name = String.isBlank(documentId) ? t.name : (t.name + '_' + documentId);
				this.tabLabel = String.isBlank(t.key) ? '_DAL_ ' + this.name : t.key;
				if (String.isNotBlank(t.path)) {
					this.mergeField = new APIMergeField(t);
				}
				if (String.isNotBlank(t.autoPlaceText)) {
					this.anchorString = t.autoPlaceText;
					this.anchorIgnoreIfNotPresent = 'true';
				}
				if (t.value != null) {
					if (t.type == Tab.TYPE_CHECKBOX) {
						this.selected = String.valueOf(t.value);
					} else if (t.value instanceof Datetime) {
						this.value = StringUtils.formatDatetime((Datetime)t.value);
					} else {
						this.value = String.valueOf(t.value);
					}
				}
			}
		}

		@TestVisible
		private Object convertValue(final String type) {
			// Don't try to convert values of a type that makes no sense to Salesforce
			if (!Tab.isValidMergeFieldType(type)) return null;

			Object result = null;
			if (type == Tab.TYPE_NUMBER || type == Tab.TYPE_FORMULA) {
				result = StringUtils.parseDecimal(this.value);
			} else if (type == Tab.TYPE_CHECKBOX) {
				result = StringUtils.parseBoolean(this.selected);
			} else if (type == Tab.TYPE_DATE || type == Tab.TYPE_DATE_SIGNED) {
				result = StringUtils.parseDate(this.value);
			} else { // text type--just use string value
				result = this.value;
			}
			return result;
		}

		public Tab toTab(final String type) {
			return new Tab(
				UUID.tryParse(this.customTabId),
				type,
				nullIfBlank(this.name),
				this.tabLabel,
				this.mergeField == null ? null : nullIfBlank(this.mergeField.path),
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.writeBack),
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.allowSenderToEdit),
				this.anchorString)
				.withValue(convertValue(type));

		}
	}

	private static APITabs addTabs(
		final APITabs apiTabs,
		final String documentId,
		final String recipientId,
		final List<Tab> tabs) {

		for (Tab t : tabs) {
			if (t == null) continue;

			if (t.type == Tab.TYPE_APPROVE) {
				apiTabs.approveTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_CHECKBOX) {
				apiTabs.checkboxTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_COMPANY) {
				apiTabs.companyTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DATE_SIGNED) {
				apiTabs.dateSignedTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DATE) {
				apiTabs.dateTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DECLINE) {
				apiTabs.declineTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_EMAIL_ADDRESS) {
				apiTabs.emailAddressTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_EMAIL) {
				apiTabs.emailTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_ENVELOPE_ID) {
				apiTabs.envelopeIdTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FIRST_NAME) {
				apiTabs.firstNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FORMULA) {
				apiTabs.formulaTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FULL_NAME) {
				apiTabs.fullNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_INITIAL_HERE) {
				apiTabs.initialHereTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_LAST_NAME) {
				apiTabs.lastNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_LIST) {
				apiTabs.listTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NOTARIZE) {
				apiTabs.notarizeTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NOTE) {
				apiTabs.noteTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NUMBER) {
				apiTabs.numberTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_RADIO_GROUP) {
				apiTabs.radioGroupTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SIGNER_ATTACHMENT) {
				apiTabs.signerAttachmentTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SIGN_HERE) {
				apiTabs.signHereTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SMART_SECTION) {
				apiTabs.smartSectionTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SSN) {
				apiTabs.ssnTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_TITLE) {
				apiTabs.titleTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_VIEW) {
				apiTabs.viewTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_ZIP) {
				apiTabs.zipTabs.add(new APITab(documentId, recipientId, t));
			} else { // Text
				apiTabs.textTabs.add(new APITab(documentId, recipientId, t));
			}
		}

		return apiTabs;
	}

	private static APITabs addDefaultTabs(
		final APITabs apiTabs,
		final String documentId,
		final String recipientId,
		final Integer roleValue) {

		apiTabs.companyTabs.add(new APITab(documentId, recipientId, roleValue, 'Company', 'co', true));
		apiTabs.dateSignedTabs.add(new APITab(documentId, recipientId, roleValue, 'DateSigned', 'd', true));
		apiTabs.fullNameTabs.add(new APITab(documentId, recipientId, roleValue, 'FullName', 'n', true));
		apiTabs.initialHereTabs.add(new APITab(documentId, recipientId, roleValue, 'InitialHere', 'i', true));
		apiTabs.initialHereTabs.add(new APITab(documentId, recipientId, roleValue, 'InitialHereOptional', 'oi', false));
		apiTabs.signHereTabs.add(new APITab(documentId, recipientId, roleValue, 'SignHere', 's', true));
		apiTabs.textTabs.add(new APITab(documentId, recipientId, roleValue, 'Text', 'txr', true));
		apiTabs.textTabs.add(new APITab(documentId, recipientId, roleValue, 'Text', 'txo', false));
		apiTabs.titleTabs.add(new APITab(documentId, recipientId, roleValue, 'Title', 't', true));

		return apiTabs;
	}

	@TestVisible
	private class APITabs {
		public List<APITab> approveTabs;
		public List<APITab> checkboxTabs;
		public List<APITab> companyTabs;
		public List<APITab> dateSignedTabs;
		public List<APITab> dateTabs;
		public List<APITab> declineTabs;
		public List<APITab> emailAddressTabs;
		public List<APITab> emailTabs;
		public List<APITab> envelopeIdTabs;
		public List<APITab> firstNameTabs;
		public List<APITab> formulaTabs;
		public List<APITab> fullNameTabs;
		public List<APITab> initialHereTabs;
		public List<APITab> lastNameTabs;
		public List<APITab> listTabs;
		public List<APITab> notarizeTabs;
		public List<APITab> noteTabs;
		public List<APITab> numberTabs;
		public List<APITab> radioGroupTabs;
		public List<APITab> signerAttachmentTabs;
		public List<APITab> signHereTabs;
		public List<APITab> smartSectionTabs;
		public List<APITab> ssnTabs;
		public List<APITab> textTabs;
		public List<APITab> titleTabs;
		public List<APITab> viewTabs;
		public List<APITab> zipTabs;

		public APITabs() {
			this.approveTabs = new List<APITab>();
			this.checkboxTabs = new List<APITab>();
			this.companyTabs = new List<APITab>();
			this.dateSignedTabs = new List<APITab>();
			this.dateTabs = new List<APITab>();
			this.declineTabs = new List<APITab>();
			this.emailAddressTabs = new List<APITab>();
			this.emailTabs = new List<APITab>();
			this.envelopeIdTabs = new List<APITab>();
			this.firstNameTabs = new List<APITab>();
			this.formulaTabs = new List<APITab>();
			this.fullNameTabs = new List<APITab>();
			this.initialHereTabs = new List<APITab>();
			this.lastNameTabs = new List<APITab>();
			this.listTabs = new List<APITab>();
			this.notarizeTabs = new List<APITab>();
			this.noteTabs = new List<APITab>();
			this.numberTabs = new List<APITab>();
			this.radioGroupTabs = new List<APITab>();
			this.signerAttachmentTabs = new List<APITab>();
			this.signHereTabs = new List<APITab>();
			this.smartSectionTabs = new List<APITab>();
			this.ssnTabs = new List<APITab>();
			this.textTabs = new List<APITab>();
			this.titleTabs = new List<APITab>();
			this.viewTabs = new List<APITab>();
			this.zipTabs = new List<APITab>();
		}

		public APITabs(
			final String documentId,
			final String recipientId,
			final List<Tab> tabs,
			final Boolean addDefault,
			final Integer roleValue) {

			this();

			if (tabs != null) addTabs(this, documentId, recipientId, tabs);
			if (addDefault) addDefaultTabs(this, documentId, recipientId, roleValue);
		}

		public List<Tab> toTabs() {
			List<Tab> result = new List<Tab>();
			if (this.approveTabs != null) {
				for (APITab t : this.approveTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_APPROVE));
				}
			}
			if (this.checkboxTabs != null) {
				for (APITab t : this.checkboxTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_CHECKBOX));
				}
			}
			if (this.companyTabs != null) {
				for (APITab t : this.companyTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_COMPANY));
				}
			}
			if (this.dateSignedTabs != null) {
				for (APITab t : this.dateSignedTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DATE_SIGNED));
				}
			}
			if (this.dateTabs != null) {
				for (APITab t : this.dateTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DATE));
				}
			}
			if (this.declineTabs != null) {
				for (APITab t : this.declineTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DECLINE));
				}
			}
			if (this.emailAddressTabs != null) {
				for (APITab t : this.emailAddressTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_EMAIL_ADDRESS));
				}
			}
			if (this.emailTabs != null) {
				for (APITab t : this.emailTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_EMAIL));
				}
			}
			if (this.envelopeIdTabs != null) {
				for (APITab t : this.envelopeIdTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_ENVELOPE_ID));
				}
			}
			if (this.firstNameTabs != null) {
				for (APITab t : this.firstNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FIRST_NAME));
				}
			}
			if (this.formulaTabs != null) {
				for (APITab t : this.formulaTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FORMULA));
				}
			}
			if (this.fullNameTabs != null) {
				for (APITab t : this.fullNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FULL_NAME));
				}
			}
			if (this.initialHereTabs != null) {
				for (APITab t : this.initialHereTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_INITIAL_HERE));
				}
			}
			if (this.lastNameTabs != null) {
				for (APITab t : this.lastNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_LAST_NAME));
				}
			}
			if (this.listTabs != null) {
				for (APITab t : this.listTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_LIST));
				}
			}
			if (this.notarizeTabs != null) {
				for (APITab t : this.notarizeTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NOTARIZE));
				}
			}
			if (this.noteTabs != null) {
				for (APITab t : this.noteTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NOTE));
				}
			}
			if (this.numberTabs != null) {
				for (APITab t : this.numberTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NUMBER));
				}
			}
			if (this.radioGroupTabs != null) {
				for (APITab t : this.radioGroupTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_RADIO_GROUP));
				}
			}
			if (this.signerAttachmentTabs != null) {
				for (APITab t : this.signerAttachmentTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SIGNER_ATTACHMENT));
				}
			}
			if (this.signHereTabs != null) {
				for (APITab t : this.signHereTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SIGN_HERE));
				}
			}
			if (this.smartSectionTabs != null) {
				for (APITab t : this.smartSectionTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SMART_SECTION));
				}
			}
			if (this.ssnTabs != null) {
				for (APITab t : this.ssnTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SSN));
				}
			}
			if (this.textTabs != null) {
				for (APITab t : this.textTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_TEXT));
				}
			}
			if (this.titleTabs != null) {
				for (APITab t : this.titleTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_TITLE));
				}
			}
			if (this.viewTabs != null) {
				for (APITab t : this.viewTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_VIEW));
				}
			}
			if (this.zipTabs != null) {
				for (APITab t : this.zipTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_ZIP));
				}
			}
			return result;
		}

		private List<Tab> toMergeFields(
			final String type,
			final List<APITab> tabs,
			final Boolean writeBackOnly) {

			List<Tab> result = new List<Tab>();
			if (tabs != null) {
				for (APITab t : tabs) {
					if (t == null || t.mergeField == null || t.mergeField.configurationType != 'salesforce' || String.isBlank(t.mergeField.path)) continue;

					if (!writeBackOnly || t.mergeField.writeBack == 'true') {
						Tab tt = t.toTab(type);
						result.add(tt);
					}
				}
			}
			return result;
		}

		public List<Tab> toMergeFields(final Boolean writeBackOnly) {
			List<Tab> result = new List<Tab>();
			result.addAll(this.toMergeFields(Tab.TYPE_APPROVE, this.approveTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_CHECKBOX, this.checkboxTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_COMPANY, this.companyTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_DATE_SIGNED, this.dateSignedTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_DATE, this.dateTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_DECLINE, this.declineTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_EMAIL_ADDRESS, this.emailAddressTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_EMAIL, this.emailTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_ENVELOPE_ID, this.envelopeIdTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_FIRST_NAME, this.firstNameTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_FORMULA, this.formulaTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_FULL_NAME, this.fullNameTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_INITIAL_HERE, this.initialHereTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_LAST_NAME, this.lastNameTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_LIST, this.listTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_NOTARIZE, this.notarizeTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_NOTE, this.noteTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_NUMBER, this.numberTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_RADIO_GROUP, this.radioGroupTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_SIGNER_ATTACHMENT, this.signerAttachmentTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_SIGN_HERE, this.signHereTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_SMART_SECTION, this.smartSectionTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_SSN, this.ssnTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_TEXT, this.textTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_TITLE, this.titleTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_VIEW, this.viewTabs, writeBackOnly));
			result.addAll(this.toMergeFields(Tab.TYPE_ZIP, this.zipTabs, writeBackOnly));
			return result;
		}
	}

	@TestVisible
	private class APIInlineTemplate {
		public String sequence;
		public List<APIDocument> documents;
		public APIRecipients recipients;
		public APICustomFields customFields;

		public APIInlineTemplate(
			final Document doc,
			final Integer sequence,
			final List<Recipient> recipients,
			final Map<String, Blob> documentContent,
			final List<CustomField> customFields,
			final Envelope.Options options,
			final Entity source) {

			if (doc != null) {
				this.sequence = String.valueOf(sequence);
				if (doc.type != Document.TYPE_TEMPLATE) {
					Blob content = String.isBlank(doc.sourceId) ? null : documentContent.get(doc.sourceId);
					this.documents = new List<APIDocument> {
						new APIDocument(doc, content)
					};
				}
				if (recipients != null) {
					this.recipients = new APIRecipients(
						recipients,
						this.sequence,
						options != null && options.includeDefaultAutoPlaceTags);
				}
				this.customFields = buildCustomFields(
					customFields,
					options,
					source);
			}
		}
	}

	@TestVisible
	private class APIServerTemplate {
		public String templateId;
		public String sequence;

		public APIServerTemplate(
			final UUID templateId,
			final Integer sequence) {

			this.templateId = String.valueOf(templateId);
			this.sequence = String.valueOf(sequence);
		}
	}

	@TestVisible
	private class APICompositeTemplate {
		public APIDocument document;
		public List<APIInlineTemplate> inlineTemplates;
		public List<APIServerTemplate> serverTemplates;

		public APICompositeTemplate(
			final Document document,
			final Integer sequence,
			final List<Recipient> recipients,
			final Map<String, Blob> documentContent,
			final List<CustomField> customFields,
			final Envelope.Options options,
			final Entity source) {

			if (document != null) {
				if (document.templateId != null) {
					this.serverTemplates = new List<APIServerTemplate> {
						new APIServerTemplate(
							document.templateId,
							sequence)
					};
				}
				this.inlineTemplates = new List<APIInlineTemplate> {
					new APIInlineTemplate(
						document,
						sequence,
						recipients,
						documentContent,
						customFields,
						options,
						source)
				};
			}
		}
	}

	@TestVisible
	private static APITextCustomField getDocumentWriteBackCustomField(
		final Envelope.DocumentWriteBack documentWriteBack,
		final Id sourceId) {

		APITextCustomField result = null;
		if (documentWriteBack != null
			&& (String.isNotBlank(documentWriteBack.linkedEntityId)
			|| String.isNotBlank(sourceId))) {

			result = new APITextCustomField(
				'##SFDocumentWriteBack',
				String.format('{0}~{1}~{2}~{3}', new List<Object> {
					String.isBlank(documentWriteBack.linkedEntityId)
						? sourceId : documentWriteBack.linkedEntityId,
					String.isBlank(documentWriteBack.nameFormat)
						? Envelope.FORMAT_NAME_PDF : documentWriteBack.nameFormat,
					documentWriteBack.combineDocuments ? 1 : 0,
					documentWriteBack.includeCertificateOfCompletion ? 1 : 0
				}),
				false,
				false);
		}
		return result;
	}

	@TestVisible
	private static APICustomFields buildCustomFields(
		final List<CustomField> customFields,
		final Envelope.Options options,
		final Entity source) {

		// Add mandatory custom fields to identify user, app, company, and Salesforce org URLs
		List<APIListCustomField> listCustomFields = new List<APIListCustomField>();
		List<APITextCustomField> textCustomFields = new List<APITextCustomField> {
			new APITextCustomField(
				'##SFUsername',
				UserInfo.getUserName(),
				false,
				false),
			new APITextCustomField(
				'##SFBaseUrl',
				Salesforce.baseUrl.toExternalForm(),
				false,
				false),
			new APITextCustomField(
				'##SFTokenEndpoint',
				Salesforce.oauthUrl.toExternalForm(),
				false,
				false),
			new APITextCustomField(
				'##SFApplication',
				Application.name + ' ' + String.valueOf(Application.version),
				false,
				false),
			new APITextCustomField(
				'Company',
				UserInfo.getOrganizationName(),
				false,
				false)
		};

		if (Entity.isValid(source)) {
			CustomField cf = CustomField.forEnvelopeSource(source.id);
			if (cf != null) textCustomFields.add(new APITextCustomField(cf));
		}

		// Create custom field for document write-back
		if (options != null) {
			APITextCustomField df = getDocumentWriteBackCustomField(
				options.documentWriteBack,
				source == null ? null : source.id);
			if (df != null) textCustomFields.add(df);
		}

		// Add user-defined custom fields
		if (customFields != null) {
			for (CustomField cf : customFields) {
				if (cf != null) {
					if (cf.type == 'text') {
						textCustomFields.add(new APITextCustomField(cf));
					} else {
						listCustomFields.add(new APIListCustomField(cf));
					}
				}
			}
		}

		return new APICustomFields(textCustomFields, listCustomFields);
	}

	@TestVisible
	// FIXME. Don't think this logic is entirely correct. Copied from DocuSignCreateAndSendEnvelope.
	// FIXME? Why are default anchor tags added to each envelope recipient, and only once for the first composite template? Confusing!
	private static List<APICompositeTemplate> buildCompositeTemplates(
		final List<Document> documents,
		final List<Recipient> recipients,
		final Map<String, Blob> documentContent,
		final List<CustomField> customFields,
		final Envelope.Options options,
		final Entity source) {

		List<APICompositeTemplate> compositeTemplates = null;
		if (documents != null) {
			compositeTemplates = new List<APICompositeTemplate>();
			Envelope.Options os = options;
			Integer sequence = 1;
			for (Document d : documents) {
				// FIXME: All recipients should not be added to every document in every case.
				compositeTemplates.add(new APICompositeTemplate(
					d,
					sequence++,
					recipients,
					documentContent,
					customFields,
					os,
					source));
				os = new Envelope.Options(
					false,
					options.documentWriteBack,
					options.envelopeEventUpdates,
					options.recipientEventUpdates);
			}
		}
		return compositeTemplates;
	}

	private static Map<String, Blob> getDocumentContent(final Map<SObjectType, Set<Id>> sourceMap) {
		if (sourceMap == null) return new Map<String, Blob>();

		Map<String, Blob> result = new Map<String, Blob>();
		for (SObjectType type : sourceMap.keySet()) {
			for (DocumentResolver resolver : DOCUMENT_RESOLVERS) {
				if (resolver.canResolveDocuments(type)) {
					Map<Id, Blob> m = resolver.getDocumentContent(type, sourceMap.get(type));
					if (m != null) {
						for (Id id : m.keySet()) {
							result.put(id, m.get(id));
						}
						break;
					}
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Id getDocumentSourceId(final Entity source) {
		if (source == null || source.id == null) return null;

		Id result = source.id;
		if (source.type == ContentDocument.getSObjectType()) { // Get latest published content version ID
			ContentDocument cd = (ContentDocument)Collection.head([
				SELECT LatestPublishedVersionId
				FROM ContentDocument
				WHERE Id = :source.id
				ORDER BY Id
				LIMIT 1
			]);
			if (cd != null) result = cd.LatestPublishedVersionId;
		}
		return result;
	}

	@TestVisible
	private static Map<String, Blob> getDocumentContent(
		final List<Document> documents,
		final Boolean fetchDocuments) {

		if (documents == null) return new Map<String, Blob>();

		Map<String, Blob> result = new Map<String, Blob>();
		Map<SObjectType, Set<Id>> sourceMap = new Map<SObjectType, Set<Id>>();
		for (Document d : documents) {
			if (d.type == Document.TYPE_TEMPLATE || String.isBlank(d.sourceId)) continue;

			// TODO: Verify non-Community restriction on document fetch.
			if (d.type == Document.TYPE_SCM) { // content is SCM file ID
				result.put(d.sourceId, Blob.valueOf('scm:' + d.sourceId));
			} else { // Salesforce document source
				Entity source = new Entity(d.sourceId);
				if (!isHtml(d) && fetchDocuments && !Salesforce.isCommunitySite) { // content is SFDC document ID
					result.put(source.id, Blob.valueOf(getDocumentSourceId(source)));
				} else if (sourceMap.containsKey(source.type)) { // content is SFDC document bytes
					sourceMap.get(source.type).add(source.id);
				} else {
					sourceMap.put(source.type, new Set<Id> { source.id });
				}
			}
		}

		// resolve any document content in source map
		result.putAll(getDocumentContent(sourceMap));

		// did we resolve all the documents?
		List<String> missingContent = new List<String>();
		for (Document d : documents) {
			if (d.type != Document.TYPE_TEMPLATE
				&& String.isNotBlank(d.sourceId)
				&& result.get(d.sourceId) == null) {

				missingContent.add(String.format('{0} ({1})', new List<String> { d.name, d.sourceId }));
			}
		}

		// if any document could not be resolved, throw an exception
		if (Collection.isNotEmpty(missingContent)) {
			throw new DocuSignException(String.format(Label.CannotReadDocumentContent_1, new List<String> {
				Collection.mkString(missingContent, ', ')
			}));
		}

		return result;
	}

	@TestVisible
	private class APIEnvelope {
		public String envelopeId;
		public String status;
		public String transactionId;
		public APICustomFields customFields;
		public List<APIDocument> documents;
		public APIRecipients recipients;
		public List<APICompositeTemplate> compositeTemplates;
		public String emailBlurb;
		public String emailSubject;
		public APINotifications notification;
		public APITabs tabs;
		public String completedDateTime;
		public String declinedDateTime;
		public String sentDateTime;
		public String voidedDateTime;
		public String voidedReason;

		public APIEnvelope(
			final Envelope e,
			final Boolean send,
			final Boolean fetchDocuments) {

			if (e != null) {
				this.status = send ? 'sent' : 'created';
				this.transactionId = e.id;
				this.emailBlurb = e.emailMessage;
				this.emailSubject = e.emailSubject;
				this.notification = new APINotifications(e.notifications);

				Map<String, Blob> documentContent =
					e.hasDocuments ? getDocumentContent(e.documents, fetchDocuments) : null;
				if (e.hasTemplates) {
					this.compositeTemplates = buildCompositeTemplates(
						e.documents,
						e.recipients,
						documentContent,
						e.customFields,
						e.options,
						e.source);
				} else {
					if (e.documents != null) {
						this.documents = new List<EnvelopeAPI.APIDocument>();
						for (Document d : e.documents) {
							this.documents.add(new APIDocument(d,
								d.type != Document.TYPE_TEMPLATE && String.isNotBlank(d.sourceId)
									? documentContent.get(d.sourceId) : null));
						}
					}
					if (e.recipients != null) {
						this.recipients = new APIRecipients(
							e.recipients,
							null,
							e.options != null && e.options.includeDefaultAutoPlaceTags != null && e.options.includeDefaultAutoPlaceTags);
					}
					this.customFields = buildCustomFields(
						e.customFields,
						e.options,
						e.source);
				}
			}
		}

		private Datetime getCompletedDatetime() {
			Datetime result = null;
			if (this.status == Envelope.STATUS_VOIDED) {
				result = StringUtils.parseDatetime(this.voidedDateTime);
			} else if (this.status == Envelope.STATUS_DECLINED) {
				result = StringUtils.parseDatetime(this.declinedDateTime);
			} else if (this.status == Envelope.STATUS_COMPLETED) {
				result = StringUtils.parseDatetime(this.completedDateTime);
			}
			return result;
		}

		public Envelope.Status toStatus() {
			Datetime sent = StringUtils.parseDatetime(this.sentDateTime);
			return new Envelope.Status(
				null, // id
				null, // source
				UUID.parse(this.envelopeId),
				this.status == null ? null : this.status.toLowerCase(),
				UserInfo.getName(),
				UserInfo.getUserEmail(),
				this.recipients == null ? null : this.recipients.toStatus(),
				sent,
				sent != null
					&& this.notification != null
					&& this.notification.expirations != null
					&& String.isNotBlank(this.notification.expirations.expireAfter)
					? sent.addDays(Integer.valueOf(this.notification.expirations.expireAfter)) : null,
				getCompletedDatetime(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.voidedReason),
				Datetime.now());
		}
	}

	@TestVisible
	private class APIEnvelopeResponse {
		public String envelopeId;
	}

	@TestVisible
	private String getExternalUrl() {
		return String.format('{0}/services/Soap/u/{1}/{2}', new List<String> {
			Salesforce.baseUrl.toExternalForm(), String.valueOf(Salesforce.API_VERSION), UserInfo.getOrganizationId()
		});
	}

	@TestVisible
	private Map<String, String> getCreateHeaders(final String senderToken) {
		Map<String, String> headers = new Map<String, String>(getDefaultHeaders());
		// Must append magic header to create envelope calls. This allows DocuSign to reach back into Salesforce to
		// retrieve documents as SFDC doesn't allow sending big blobs via web service callouts.
		headers.put('X-DocuSign-ExternalInfo', String.format(
			'<ExternalInfo><ExternalSessionId>{0}</ExternalSessionId><ExternalUrl>{1}</ExternalUrl></ExternalInfo>',
			new List<String> { UserInfo.getSessionId(), getExternalUrl() }));
		headers.put('User-Agent', Application.userAgent + ' ' + senderToken);
		return headers;
	}

	public UUID createEnvelope(
		final Envelope envelope,
		final Boolean sendNow,
		final String senderToken) {

		return this.createEnvelope(envelope, sendNow, senderToken, RestAPI.defaultTimeout);
	}

	public UUID createEnvelope(
		final Envelope envelope,
		final Boolean sendNow,
		final String senderToken,
		final Integer timeout) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		RestAPI.Response response = this.post(
			getBaseUrl(),
			new List<Object> { 'envelopes' },
			sendNow ? new QueryString('merge_roles_on_draft', 'true') : QueryString.empty,
			getCreateHeaders(senderToken),
			JSON.serialize(new EnvelopeAPI.APIEnvelope(
				envelope,
				sendNow,
				Salesforce.isApiSupported && Permissions.isApiEnabled()),
				true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create envelope: ' + response.error.toString());
			APIError error;
			// TODO: Don't (ab)use String.contains. Slow/inefficient. Use equality comparison on DS error code. Need to determine what they are for these cases.
			if (response.error.description.containsIgnoreCase('Signers that are required to meet 21 CFR part 11')) {
				error = new APIError(APIErrorCode.FAILED_TO_MEET_21_CFR_PART_11, Label.Failed21CFRPart11);
			} else if (response.error.description.containsIgnoreCase('Account settings indicate the recipient must be an active DocuSign user')) {
				error = new APIError(APIErrorCode.USER_NOT_ACTIVATED, Label.RecipientMustBeUser);
			} else if (response.error.description.containsIgnoreCase('trialexpired')) {
				error = new APIError(APIErrorCode.TRIAL_ACCOUNT_EXPIRED, Label.TrialAccountExpired);
			} else if (response.error.description.containsIgnoreCase('unable to convert this document')) {
				error = new APIError(APIErrorCode.INVALID_DOCUMENT, Label.InvalidFileExtension);
			} else if (response.error.description.containsIgnoreCase('account lacks sufficient permissions')) {
				error = new APIError(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, Label.AccountInSessionSigningMustBeEnabled);
			} else if (response.error.description.containsIgnoreCase('Group has no members')) {
				error = new APIError(APIErrorCode.INVALID_SIGNING_GROUP, Label.EmptySigningGroup);
			} else if (response.error.description.containsIgnoreCase('user name for the recipient is invalid')) {
				throw new APIException(new APIError(APIErrorCode.INVALID_RECIPIENT, Label.InvalidRecipientUsername));
			} else {
				error = response.error;
			}
			throw new APIException(error);
		}
		return UUID.parse(((APIEnvelopeResponse)JSON.deserialize(response.body, APIEnvelopeResponse.class)).envelopeId);
	}

	@TestVisible
	private class APIVoidRequest {
		public String status;
		public String voidedReason;

		public APIVoidRequest(final String reason) {
			this.status = 'voided';
			this.voidedReason = reason;
		}
	}

	public Boolean voidEnvelope(
		final UUID envelopeId,
		final String reason) {

		return this.voidEnvelope(envelopeId, reason, RestAPI.defaultTimeout);
	}

	public Boolean voidEnvelope(
		final UUID envelopeId,
		final String reason,
		final Integer timeout) {

		RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId },
			JSON.serialize(new APIVoidRequest(reason)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to void envelope: ' + response.error.toString());
			APIError error;
			if (response.error.description.contains('This user is not the sender of the envelope.')) {
				error = new APIError(APIErrorCode.UNAUTHORIZED, Label.NotEnvelopeOwner);
			} else {
				error = response.error;
			}
			throw new APIException(error);
		}
		return true;
	}

	public Envelope.Status getEnvelopeStatus(
		final UUID envelopeId,
		final Boolean includeRecipients) {

		return getEnvelopeStatus(envelopeId, includeRecipients, RestAPI.defaultTimeout);
	}

	public Envelope.Status getEnvelopeStatus(
		final UUID envelopeId,
		final Boolean includeRecipients,
		final Integer timeout) {

		RestAPI.Response response = this.get(
			new List<Object> { 'envelopes', String.valueOf(envelopeId) },
			includeRecipients ? new QueryString(new Map<String, String> {
				'include' => 'recipients',
				'advanced_update' => 'true'
			}) : QueryString.empty,
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve envelope: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return ((APIEnvelope)JSON.deserialize(response.body, APIEnvelope.class)).toStatus();
	}

	@TestVisible
	private class APITemplateId {
		public String templateId;
		public String name;
		public String lastModified;

		public APITemplateId(
			final UUID id,
			final String name) {

			this.templateId = String.valueOf(id);
			this.name = name;
		}
	}

	private static String nullIfBlank(final String s) {
		return String.isBlank(s) ? null : s;
	}

	@TestVisible
	private class APITemplateUpdateDocuments {
		public List<APIDocument> documents;
		public APITemplateUpdateDocuments(final List<APIDocument> documents) {
			this.documents = Collection.isNotEmpty(documents) ? documents : new List<APIDocument>();
		}
	}

	@TestVisible
	private class APITemplate {
		public APITemplateId envelopeTemplateDefinition;
		public APICustomFields customFields;
		public List<APIDocument> documents;
		public APIRecipients recipients;
		public String emailBlurb;
		public String emailSubject;
		public APINotifications notification;
		public APITabs tabs;

		public APITemplate(final Template template) {
			if (template != null) {
				this.envelopeTemplateDefinition = new APITemplateId(template.id, template.name);
				if (String.isNotBlank(template.emailSubject)) this.emailSubject = template.emailSubject;
				if (String.isNotBlank(template.emailMessage)) this.emailBlurb = template.emailMessage;
				this.notification = new APINotifications(template.notifications);
				if (Collection.isNotEmpty(template.documents)) {
					Map<String, Blob> documentContent = getDocumentContent(
						template.documents,
						false); // TODO: Enable document fetch for templates. Requires platform change.
					this.documents = new List<APIDocument>();
					for (Document d : template.documents) {
						this.documents.add(new APIDocument(d,
							d.type != Document.TYPE_TEMPLATE && String.isNotBlank(d.sourceId)
								? documentContent.get(d.sourceId) : null));
					}
				}
				if (Collection.isNotEmpty(template.recipients)) {
					this.recipients = new APIRecipients(
						template.recipients,
						null,
						false); // TODO: Make configurable?
				}
				this.customFields = buildCustomFields(
					template.customFields,
					null, // TODO: Wire up document write-back
					null);
			}
		}

		public Template toTemplate() {
			List<Document> docs = new List<Document>();
			if (this.documents != null) {
				for (EnvelopeAPI.APIDocument d : this.documents) {
					docs.add(d.toDocument());
				}
			}

			return new Template(
				this.envelopeTemplateDefinition == null ? null : UUID.parse(envelopeTemplateDefinition.templateId),
				this.envelopeTemplateDefinition == null ? null : nullIfBlank(envelopeTemplateDefinition.name),
				this.customFields == null ? new List<CustomField>() : this.customFields.toCustomFields(),
				this.notification == null ? null : this.notification.toNotifications(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				docs,
				this.recipients == null ? new List<Recipient>() : this.recipients.toRecipients(),
				this.envelopeTemplateDefinition == null
					? null : StringUtils.parseDatetime(this.envelopeTemplateDefinition.lastModified));
		}
	}

	@TestVisible
	private class APITemplateListResult {
		public String templateId;
		public String name;
		public APICustomFields customFields;
		public APINotifications notification;
		public String emailSubject;
		public String emailBlurb;
		public APIRecipients recipients;
		public String lastModified;

		public Template toTemplate() {
			return new Template(
				UUID.parse(this.templateId),
				nullIfBlank(this.name),
				this.customFields == null ? new List<CustomField>() : this.customFields.toCustomFields(),
				this.notification == null ? null : this.notification.toNotifications(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				this.recipients == null ? new List<Recipient>() : this.recipients.toRecipients(),
				StringUtils.parseDatetime(this.lastModified));
		}
	}

	@TestVisible
	private class APITemplates {
		public String resultSetSize;
		public String startPosition;
		public String endPosition;
		public String totalSetSize;
		public List<APITemplateListResult> envelopeTemplates;

		public List<Template> toTemplates() {
			final List<Template> templates = new List<Template>();
			if (this.envelopeTemplates != null) {
				for (APITemplateListResult t : this.envelopeTemplates) {
					templates.add(t.toTemplate());
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
		RestAPI.Response response = this.get(
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

		List<Template> templates = ((APITemplates)JSON.deserialize(response.body, APITemplates.class)).toTemplates();
		for (Template t : templates) {
			templateMap.put(t.id, t);
		}
		return templates;
	}

	public Template getTemplate(final UUID templateId) {
		return this.getTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Template getTemplate(
		final UUID templateId,
		final Integer timeout) {

		if (templateMap.containsKey(templateId)) return templateMap.get(templateId);

		RestAPI.Response response = this.get(
			new List<Object> { 'templates', templateId },
			new QueryString('include', 'custom_fields,notifications,recipients'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template: ' + response.error);
			throw new APIException(response.error);
		}

		Template template = ((APITemplate)JSON.deserialize(response.body,
			APITemplate.class)).toTemplate();
		templateMap.put(template.id, template);
		return template;
	}

	public Template createTemplate(final Template template) {
		return this.createTemplate(template, RestAPI.defaultTimeout);
	}

	public Template createTemplate(
		final Template template,
		final Integer timeout) {

		if (template == null) throw new DocuSignException(Label.UndefinedTemplate);

		RestAPI.Response response = this.post(
			'templates',
			JSON.serialize(new APITemplate(template), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create templates: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return template.withId(UUID.tryParse((String)resp.get('templateId'))).withLastModified(Datetime.now());
	}

	public Template updateTemplate(final Template template) {
		return this.updateTemplate(template, RestAPI.defaultTimeout);
	}

	public Template updateTemplate(
		final Template template,
		final Integer timeout) {

		if (template == null) throw new DocuSignException(Label.UndefinedTemplate);
		if (template.id == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		APITemplate updateTemplateRequest = new APITemplate(template);
		List<APIDocument> updateTemplateDocumentsRequest = Collection.isNotEmpty(updateTemplateRequest.documents) ? updateTemplateRequest.documents : null;
		//null out the documents in the updateTemplateRequest since
		//documents will be updated using updateTemplateDocumentsRequest and a separate endpoint
		updateTemplateRequest.documents = null;

		//TODO : Add DAL appropriate customFields to template
		//null out the custom fields since we will have to
		//decide the appropriate fields for DAL templates as well as use logic to retrieve this fieldIds
		updateTemplateRequest.customFields = null;

		//TODO : Add error handling to cover both multi item put requests viz;
		//'templates/{templateId}' and 'templates/{templateId}/documents'
		//this will require updates to RestAPI.cls and will be covered in follow up JIRA ticket
		RestAPI.Response response = this.put(
			new List<Object> { 'templates', template.id },
			JSON.serialize(updateTemplateRequest, true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update template: ' + response.error);
			throw new APIException(response.error);
		}

		if (Collection.isNotEmpty(updateTemplateDocumentsRequest)) {
			RestAPI.Response documentsResponse = this.put(
				new List<Object> { 'templates', template.id, 'documents' },
				JSON.serialize(new APITemplateUpdateDocuments(updateTemplateDocumentsRequest), true),
				timeout);
			if (documentsResponse.hasError) {
				// FIXME: Add unit test for when template update is successful but document update is not.
				this.log.error('Failed to update template documents: ' + documentsResponse.error);
				throw new APIException(documentsResponse.error);
			}
		}

		return template.withLastModified(Datetime.now());
	}

	public Boolean deleteTemplate(final UUID templateId) {
		return this.deleteTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Boolean deleteTemplate(
		final UUID templateId,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.put(
			new List<Object> { 'folders', 'recyclebin' },
			JSON.serialize(new Map<String, Object> {
				'envelopeIds' => new List<String> {
					String.valueOf(templateId)
				}
			}),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to delete template: ' + response.error);
			throw new APIException(response.error);
		}

		return response.error == APIError.none;
	}

	public List<Tab> getEnvelopeMergeFields(
		final UUID envelopeId,
		final Boolean writeBackOnly) {

		return this.getEnvelopeMergeFields(envelopeId, writeBackOnly, RestAPI.defaultTimeout);
	}

	public List<Tab> getEnvelopeMergeFields(
		final UUID envelopeId,
		final Boolean writeBackOnly,
		final Integer timeout) {

		if (UUID.isEmpty(envelopeId)) throw new DocuSignException(Label.UndefinedDocuSignEnvelopeId);

		RestAPI.Response response = this.get(
			new List<Object> { 'envelopes', envelopeId, 'recipients' },
			new QueryString('include_tabs', 'true'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get envelope merge fields: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIRecipients)JSON.deserialize(response.body, APIRecipients.class)).getMergeFields(writeBackOnly);
	}
}
