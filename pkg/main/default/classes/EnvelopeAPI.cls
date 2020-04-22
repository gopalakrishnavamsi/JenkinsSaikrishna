public with sharing class EnvelopeAPI extends ESignatureAPI {

	private static EnvelopeAPI self = null;
	private static final String ACCOUNT_LACKS_PERMISSIONS = 'ACCOUNT_LACKS_PERMISSIONS';
	private static final String RECIPIENT_NOT_IN_SEQUENCE = 'RECIPIENT_NOT_IN_SEQUENCE';
	private static final String UNKNOWN_ENVELOPE_RECIPIENT = 'UNKNOWN_ENVELOPE_RECIPIENT';
	private static final String USER_LACKS_PERMISSIONS = 'USER_LACKS_PERMISSIONS';
	private static final List<DocumentResolver> DOCUMENT_RESOLVERS = new List<DocumentResolver>();
	private static final Set<String> HTML_EXTENSIONS = new Set<String> { 'htm', 'html', 'adf' };

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

	private List<SigningGroup> sgs = null;

	private EnvelopeAPI(
		final Url baseUrl,
		final UUID accountId) {

		super(baseUrl, 'v2', accountId);
	}

	public static EnvelopeAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new EnvelopeAPI(c.environment.eSignatureBaseUrl, c.account.id);
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

	@TestVisible
	private class SigningGroupMember {
		public String userName;
		public String email;

		public SigningGroup.Member toExternalForm() {
			return new SigningGroup.Member(userName, email);
		}
	}

	@TestVisible
	private class APISigningGroup {
		public String signingGroupId;
		public String groupName;
		public List<SigningGroupMember> users;

		public SigningGroup toExternalForm() {
			final List<SigningGroup.Member> members = new List<SigningGroup.Member>();
			if (users != null) {
				for (SigningGroupMember u : users) {
					members.add(u.toExternalForm());
				}
			}
			return new SigningGroup(Integer.valueOf(signingGroupId), groupName, members);
		}
	}

	@TestVisible
	private class SigningGroups {
		public List<APISigningGroup> groups;

		public List<SigningGroup> toExternalForm() {
			final List<SigningGroup> sgs = new List<SigningGroup>();
			if (groups != null) {
				for (APISigningGroup sg : groups) {
					sgs.add(sg.toExternalForm());
				}
			}
			return sgs;
		}
	}

	public List<SigningGroup> getSigningGroups() {
		return getSigningGroups(RestAPI.defaultTimeout);
	}

	public List<SigningGroup> getSigningGroups(final Integer timeout) {
		if (this.sgs == null) {
			final RestAPI.Response response = this.get(
				'signing_groups',
				new QueryString('include_users', 'true'),
				timeout);
			if (response.hasError) {
				final String body = response.body;
				if (response.statusCode == APIErrorCode.BAD_REQUEST
					&& body.containsIgnoreCase(ACCOUNT_LACKS_PERMISSIONS)) {

					this.sgs = new List<SigningGroup>();
					throw new APIException(new APIError(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS,
						Label.SigningGroupsProhibited));
				} else {
					// TODO: Localize error description
					throw new APIException(response.error);
				}
			}

			this.sgs = ((SigningGroups)JSON.deserialize(response.body, SigningGroups.class)).toExternalForm();
		}
		return this.sgs;
	}

	// get*View Url serialization objects
	private class ViewRequest {
		public String authenticationMethod { get; private set; }
		public String email { get; private set; }
		public String returnUrl { get; private set; }
		public String userName { get; private set; }
		public String recipientId { get; private set; }
		public String envelopeId { get; private set; }
		public String clientUserId { get; private set; }
		public Boolean suppressNavigation { get; private set; }

		public ViewRequest(final UUID envelopeId, final Url returnUrl) {
			this.authenticationMethod = null;
			this.email = null;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = null;
			this.recipientId = null;
			this.envelopeId = UUID.toString(envelopeId);
			this.suppressNavigation = true;
		}

		public ViewRequest(final Url returnUrl) {
			this.authenticationMethod = null;
			this.email = null;
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.userName = null;
			this.recipientId = null;
			this.envelopeId = null;
			this.suppressNavigation = true;
		}

		public ViewRequest(final String authenticationMethod,
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
		public ViewRequest(final String authenticationMethod,
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

	private class ViewResponse {
		public String url;
	}

	public Url getSenderViewUrl(final UUID envelopeId, final Url returnUrl) {
		return this.getSenderViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getSenderViewUrl(final UUID envelopeId, final Url returnUrl, final Integer timeout) {
		final RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'sender' },
			JSON.serialize(new ViewRequest(returnUrl)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get sender view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	/*
	* Obtains recipient view for specified account envelope
	* @param envelopeId
	* @param email
	* @param userName
	*/
	public Url getRecipientViewUrl(final UUID envelopeId, final Url returnUrl, final String email, final String userName,
		final Integer recipientId) {

		return this.getRecipientViewUrl(envelopeId, returnUrl, email, userName, recipientId, RestAPI.defaultTimeout);
	}

	public Url getRecipientViewUrl(final UUID envelopeId, final Url returnUrl, final String email, final String userName,
		final Integer recipientId, final Integer timeout) {

		final RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'recipient' },
			JSON.serialize(new ViewRequest('email', email, returnUrl, userName, recipientId)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get recipient view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	//Embedded Recipient view request
	public Url getEmbeddedRecipientViewUrl(final UUID envelopeId, final Url returnUrl,
		final String email, final String userName) {

		return this.getEmbeddedRecipientViewUrl(envelopeId, returnUrl, email, userName, RestAPI.defaultTimeout);
	}

	public Url getEmbeddedRecipientViewUrl(final UUID envelopeId, final Url returnUrl,
		final String email, final String userName, final Integer timeout) {

		String clientUserId = UserInfo.getUserId();
		final RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'recipient' },
			JSON.serialize(new ViewRequest('email', clientUserId, returnUrl, userName, email)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get recipient view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	public Url getConsoleViewUrl(final UUID envelopeId, final Url returnUrl) {
		return this.getConsoleViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getConsoleViewUrl(final UUID envelopeId, final Url returnUrl, final Integer timeout) {
		final RestAPI.Response response = this.post(
			new List<Object> { 'views', 'console' },
			JSON.serialize(new ViewRequest(envelopeId, returnUrl)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get console view: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	public Url getCorrectViewUrl(final UUID envelopeId, final Url returnUrl) {
		return this.getCorrectViewUrl(envelopeId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getCorrectViewUrl(final UUID envelopeId, final Url returnUrl, final Integer timeout) {
		final RestAPI.Response response = this.post(
			new List<Object> { 'envelopes', envelopeId, 'views', 'correct' },
			JSON.serialize(new ViewRequest(returnUrl)),
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

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	public Boolean resendEnvelope(final UUID envelopeId) {
		return this.resendEnvelope(envelopeId, RestAPI.defaultTimeout);
	}

	public Boolean resendEnvelope(final UUID envelopeId, final Integer timeout) {
		Boolean isResent = false;
		final RestAPI.Response response = this.put(
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
	private class ResendResult {
		public ESignatureAPI.ErrorDetails errorDetails;
		public String recipientId;

		public Recipient.ResendResult toExternalForm(final Recipient r) {
			return new Recipient.ResendResult(
				StringUtils.parseInteger(this.recipientId, null),
				r == null ? null : r.email,
				r == null ? null : r.routingOrder,
				this.errorDetails == null ? null : getError(this.errorDetails.toExternalForm()));
		}
	}

	@TestVisible
	private class ResendResults {
		public List<ResendResult> recipientUpdateResults;

		public List<Recipient.ResendResult> toExternalForm(final Map<String, Recipient> recipients) {
			List<Recipient.ResendResult> result = new List<Recipient.ResendResult>();
			if (this.recipientUpdateResults != null) {
				for (ResendResult rr : this.recipientUpdateResults) {
					result.add(rr.toExternalForm(recipients.get(rr.recipientId)));
				}
			}
			return result;
		}
	}

	public List<Recipient.ResendResult> resendRecipients(final UUID envelopeId, final List<Recipient> recipients) {
		return this.resendRecipients(envelopeId, recipients, RestAPI.defaultTimeout);
	}

	public List<Recipient.ResendResult> resendRecipients(final UUID envelopeId, final List<Recipient> recipients,
		final Integer timeout) {

		if (envelopeId == null) throw new DocuSignException(Label.InvalidEnvelope);
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.AtLeastOneRecipientIsRequired);

		RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId, 'recipients' },
			new QueryString('resend_envelope', 'true'),
			JSON.serialize(new Recipients(recipients, null, false)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to resend envelope: ' + response.error.toString());
			throw new APIException(response.error);
		}

		Map<String, Recipient> rMap = new Map<String, Recipient>();
		for (Recipient r : recipients) {
			rMap.put(String.valueOf(r.sequence), r);
		}
		return ((ResendResults)JSON.deserialize(response.body, ResendResults.class)).toExternalForm(rMap);
	}

	// Serialization objects for templates
	@TestVisible
	private class ListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public ListCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
				this.listItems = cf.items;
			}
		}
	}

	@TestVisible
	private class TextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public TextCustomField(final String name, final String value, final Boolean required, final Boolean show) {
			this.name = name;
			this.value = value;
			this.required = String.valueOf(required);
			this.show = String.valueOf(show);
		}

		public TextCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
			}
		}
	}

	@TestVisible
	private class CustomFields {
		public List<TextCustomField> textCustomFields;
		public List<ListCustomField> listCustomFields;

		public CustomFields(final List<TextCustomField> textCustomFields, final List<ListCustomField> listCustomFields) {
			this.textCustomFields = textCustomFields;
			this.listCustomFields = listCustomFields;
		}
	}

	// Serialization objects for update in-person signer
	@TestVisible
	private class InPersonSigners {
		public List<InPersonSigner> inPersonSigners { get; private set; }

		public InPersonSigners(final String signerEmail) {
			this.inPersonSigners = new List<InPersonSigner> { new InPersonSigner(signerEmail) };
		}
	}

	@TestVisible
	private class InPersonSigner {
		public String hostName;
		public String hostEmail;
		public String signerEmail;
		public String recipientId;

		public InPersonSigner(final String signerEmail) {
			this.recipientId = '1';
			this.hostName = UserInfo.getName();
			this.hostEmail = UserInfo.getUserEmail();
			this.signerEmail = signerEmail;
		}
	}

	/**
	 Special case of update recipients API assuming current user is host, and the first recipient is in-person.
	 */
	public Boolean updateInPersonSigner(final UUID envelopeId, final String signerEmail) {
		return updateInPersonSigner(envelopeId, signerEmail, RestAPI.defaultTimeout);
	}

	public Boolean updateInPersonSigner(final UUID envelopeId, final String signerEmail, final Integer timeout) {
		final RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId, 'recipients' },
			JSON.serialize(new InPersonSigners(signerEmail)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update in-person signer: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return true;
	}

	// Serialization objects for createEnvelope
	@TestVisible
	private class Expirations {
		public String expireEnabled;
		public String expireAfter;
		public String expireWarn;

		public Expirations(final Notifications o) {
			if (o != null) {
				this.expireEnabled = String.valueOf(o.expires);
				this.expireAfter = String.valueOf(o.expireAfterDays);
				this.expireWarn = String.valueOf(o.expireWarnDays);
			}
		}
	}

	@TestVisible
	private class Reminders {
		public String reminderEnabled;
		public String reminderDelay;
		public String reminderFrequency;

		public Reminders(final Notifications o) {
			if (o != null) {
				this.reminderEnabled = String.valueOf(o.remind);
				this.reminderDelay = String.valueOf(o.remindAfterDays);
				this.reminderFrequency = String.valueOf(o.remindFrequencyDays);
			}
		}
	}

	@TestVisible
	private class EnvelopeNotification {
		public Reminders reminders;
		public Expirations expirations;
		public String useAccountDefaults;

		public EnvelopeNotification(final Notifications o, final Boolean useAccountDefaults) {
			this.reminders = new Reminders(o);
			this.expirations = new Expirations(o);
			this.useAccountDefaults = String.valueOf(useAccountDefaults);
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
			}
		}
	}

	@TestVisible
	private class SmsAuthentication {
		public List<String> senderProvidedNumbers;

		public SmsAuthentication(final List<String> ns) {
			this.senderProvidedNumbers = ns;
		}
	}

	@TestVisible
	private class RecipientNotification {
		public String supportedLanguage;
		public String emailSubject;
		public String emailBody;

		public RecipientNotification(final Recipient.EmailSettings es) {
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
		public String hostEmail;
		public String hostName;
		public String signerEmail;
		public String signerName;
		public List<String> customFields;
		public EnvelopeAPI.RecipientNotification emailNotification;
		public String accessCode;
		public String requireIdLookup;
		public String idCheckConfigurationName;
		public EnvelopeAPI.SmsAuthentication smsAuthentication;
		public String note;
		public DefaultAnchorTags tabs;
		public String status;
		public String deliveredDateTime;
		public String signedDateTime;
		public String declinedDateTime;
		public String declinedReason;
		public String clientUserId;

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
					? null : new EnvelopeAPI.RecipientNotification(r.emailSettings);
				if (r.authentication != null) {
					this.accessCode = r.authentication.accessCode;
					this.requireIdLookup = String.valueOf(r.authentication.idCheckRequired);
					if (Collection.isNotEmpty(r.authentication.smsPhoneNumbers)) {
						this.requireIdLookup = 'true';
						this.idCheckConfigurationName = 'SMS Auth $';
						this.smsAuthentication = new EnvelopeAPI.SmsAuthentication(r.authentication.smsPhoneNumbers);
					}
				}
				this.note = r.note;
				if (includeDefaultAnchorTags
					&& String.isBlank(r.envelopeRecipientId)
					&& r.role != null
					&& r.role.hasValue) {

					// Only add default anchor tags if role is defined and has a valid (> 0) value.
					this.tabs = new EnvelopeAPI.DefaultAnchorTags(documentId, this.recipientId,
						String.valueOf(r.role.value));
				}
				//setting the clientUserId property for embedded recipients
				//setting this to the Salesforce user id of the recipient
				//this will be set only for embedded recipients. If this property is set for other recipients the envelope is not sent
				if (r.type == Recipient.TYPE_EMBEDDED_SIGNER) {
					this.clientUserId = Entity.isValid(r.source) ? r.source.id : null;
				}
			}
		}

		public Recipient.Status toExternalForm(final String type) {
			Boolean inPersonSigner = type == Recipient.TYPE_IN_PERSON_SIGNER;
			return new Recipient.Status(
				null, // id
				null, // source
				type,
				null,
				this.status,
				inPersonSigner ? this.signerName : this.name,
				inPersonSigner ? this.signerEmail : this.email,
				Integer.valueOf(this.routingOrder),
				StringUtils.parseDatetime(this.deliveredDateTime),
				String.isNotBlank(this.declinedDateTime) ? StringUtils.parseDatetime(this.declinedDateTime)
					: StringUtils.parseDatetime(this.signedDateTime),
				this.declinedReason,
				Datetime.now());
		}
	}

	@TestVisible
	private static List<String> getRecipientCustomFields(final Recipient r) {
		List<String> customFields = null;
		if (r != null && r.source != null && String.isNotBlank(r.source.id) && r.source.type != null) {
			customFields = new List<String> {
				String.format('##SF{0}:{1}', new List<String> { String.valueOf(r.source.type), r.source.id })
			};
		}
		return customFields;
	}

	@TestVisible
	private class Recipients {
		public List<APIRecipient> agents;
		public List<APIRecipient> carbonCopies;
		public List<APIRecipient> certifiedDeliveries;
		public List<APIRecipient> editors;
		public List<APIRecipient> inPersonSigners;
		public List<APIRecipient> intermediaries;
		public List<APIRecipient> signers;

		public Recipients(
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
				this.signers = new List<APIRecipient>();
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
					} else { // Recipient.TYPE_SIGNER and Recipient.TYPE_EMBEDDED_SIGNER
						this.signers.add(new APIRecipient(r, documentId, includeDefaultAnchorTags));
					}
				}
			}
		}

		public List<Recipient.Status> toExternalForm() {
			List<Recipient.Status> result = new List<Recipient.Status>();
			if (this.agents != null) {
				for (EnvelopeAPI.APIRecipient r : this.agents) {
					result.add(r.toExternalForm(Recipient.TYPE_AGENT));
				}
			}
			if (this.carbonCopies != null) {
				for (EnvelopeAPI.APIRecipient r : this.carbonCopies) {
					result.add(r.toExternalForm(Recipient.TYPE_CARBON_COPY));
				}
			}
			if (this.certifiedDeliveries != null) {
				for (EnvelopeAPI.APIRecipient r : this.certifiedDeliveries) {
					result.add(r.toExternalForm(Recipient.TYPE_CERTIFIED_DELIVERY));
				}
			}
			if (this.editors != null) {
				for (EnvelopeAPI.APIRecipient r : this.editors) {
					result.add(r.toExternalForm(Recipient.TYPE_EDITOR));
				}
			}
			if (this.intermediaries != null) {
				for (EnvelopeAPI.APIRecipient r : this.intermediaries) {
					result.add(r.toExternalForm(Recipient.TYPE_INTERMEDIARY));
				}
			}
			if (this.inPersonSigners != null) {
				for (EnvelopeAPI.APIRecipient r : this.inPersonSigners) {
					result.add(r.toExternalForm(Recipient.TYPE_IN_PERSON_SIGNER));
				}
			}
			if (this.signers != null) {
				for (EnvelopeAPI.APIRecipient r : this.signers) {
					result.add(r.toExternalForm(Recipient.TYPE_SIGNER));
				}
			}
			result.sort();
			Integer sequence = 0;
			for (Recipient.Status rs : result) {
				rs = rs.withSequence(++sequence);
			}
			return result;
		}
	}

	@TestVisible
	private class AnchorTag {
		public String documentId;
		public String recipientId;
		public String name;
		public String tabLabel;
		public String anchorIgnoreIfNotPresent;
		public String required;
		public String anchorString;
		public String optional;

		public AnchorTag(final String documentId, final String recipientId, final String roleValue, final String name,
			final String anchor, final Boolean required, final String optional) {

			this.recipientId = recipientId;
			this.documentId = documentId;
			if (this.documentId == null) {
				this.name = name;
			} else {
				this.name = name + documentId;
			}
			this.tabLabel = '_DFS_' + name;
			this.anchorIgnoreIfNotPresent = 'true';
			this.anchorString = String.isNotBlank(roleValue) ? '\\' + anchor + roleValue + '\\' : '\\' + anchor + '\\';
			this.required = String.valueOf(required);
			this.optional = optional;
		}
	}

	@TestVisible
	private class DefaultAnchorTags {
		public List<AnchorTag> signHereTabs;
		public List<AnchorTag> initialHereTabs;
		public List<AnchorTag> fullNameTabs;
		public List<AnchorTag> companyTabs;
		public List<AnchorTag> titleTabs;
		public List<AnchorTag> dateSignedTabs;
		public List<AnchorTag> textTabs;

		public DefaultAnchorTags(final String documentId, final String recipientId, final String roleValue) {
			this.signHereTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'SignHere', 's', false, null)
			};
			this.initialHereTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'InitialHere', 'i', false, null),
				new AnchorTag(documentId, recipientId, roleValue, 'InitialHereOptional', 'oi', false, 'true')
			};
			this.fullNameTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'FullName', 'n', false, null)
			};
			this.companyTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'Company', 'co', true, null)
			};
			this.titleTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'Title', 't', true, null)
			};
			this.dateSignedTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'DateSigned', 'd', false, null)
			};
			this.textTabs = new List<AnchorTag> {
				new AnchorTag(documentId, recipientId, roleValue, 'Text', 'txr', true, null),
				new AnchorTag(documentId, recipientId, roleValue, 'Text', 'txo', false, null)
			};
		}
	}

	@TestVisible
	private class InlineTemplate {
		public String sequence;
		public List<APIDocument> documents;
		public Recipients recipients;
		public EnvelopeAPI.CustomFields customFields;

		public InlineTemplate(
			final Document doc,
			final Integer sequence,
			final List<Recipient> recipients,
			final Boolean includeDefaultAnchorTags,
			final Map<String, Blob> documentContent,
			final List<CustomField> customFields,
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
					this.recipients = new Recipients(
						recipients,
						this.sequence,
						includeDefaultAnchorTags);
				}
				this.customFields = buildCustomFields(customFields, source);
			}
		}
	}

	private class ServerTemplate {
		public String templateId;
		public String sequence;

		public ServerTemplate(final UUID templateId, final Integer sequence) {
			this.templateId = String.valueOf(templateId);
			this.sequence = String.valueOf(sequence);
		}
	}

	@TestVisible
	private class CompositeTemplate {
		public APIDocument document;
		public List<InlineTemplate> inlineTemplates;
		public List<ServerTemplate> serverTemplates;

		public CompositeTemplate(
			final Document document,
			final Integer sequence,
			final List<Recipient> recipients,
			final Boolean includeDefaultAnchorTags,
			final Map<String, Blob> documentContent,
			final List<CustomField> customFields,
			final Entity source) {

			if (document != null) {
				if (document.templateId != null) {
					this.serverTemplates = new List<ServerTemplate> {
						new ServerTemplate(
							document.templateId,
							sequence)
					};
				}
				this.inlineTemplates = new List<InlineTemplate> {
					new InlineTemplate(
						document,
						sequence,
						recipients,
						includeDefaultAnchorTags,
						documentContent,
						customFields,
						source)
				};
			}
		}
	}

	@TestVisible
	private static EnvelopeAPI.CustomFields buildCustomFields(
		final List<CustomField> customFields,
		final Entity source) {

		// add our custom fields that identifies the sending app
		// TODO: Determine if all these are really required or used by anyone.
		final List<EnvelopeAPI.ListCustomField> listCustomFields = new List<EnvelopeAPI.ListCustomField>();
		final List<EnvelopeAPI.TextCustomField> textCustomFields = new List<EnvelopeAPI.TextCustomField> {
			new EnvelopeAPI.TextCustomField('Company', UserInfo.getOrganizationName(), false, false),
			new EnvelopeAPI.TextCustomField('DSXPartnerApplication', Application.name + ' '
				+ String.valueOf(Application.version), false, false),
			new EnvelopeAPI.TextCustomField('PlatformName', 'Salesforce', false, false),
			new EnvelopeAPI.TextCustomField('AppName', 'DocuSignForSalesforce', false, false)
		};

		if (customFields != null) {
			for (CustomField cf : customFields) {
				if (cf != null) {
					if (cf.type == 'text') {
						textCustomFields.add(new EnvelopeAPI.TextCustomField(cf));
					} else {
						listCustomFields.add(new EnvelopeAPI.ListCustomField(cf));
					}
				}
			}
		}

		if (Entity.isValid(source)) {
			// add our customfield to identify the object we started with so we can attach docs there via connect
			textCustomFields.add(new EnvelopeAPI.TextCustomField(
				'DSFSSourceObjectId',
				source.id + '~' + source.typeName,
				false,
				false));

			// Add related object custom fields
			textCustomFields.add(new EnvelopeAPI.TextCustomField(
				'##SF' + source.typeName,
				source.id,
				false,
				false));

			if (Entity.isValid(source.parent)) {
				textCustomFields.add(new EnvelopeAPI.TextCustomField(
					'##SF' + source.parent.typeName,
					source.parent.id,
					false,
					false));
			}
		}

		return new EnvelopeAPI.CustomFields(textCustomFields, listCustomFields);
	}

	@TestVisible
	// FIXME. Don't think this logic is entirely correct. Copied from DocuSignCreateAndSendEnvelope.
	// FIXME? Why are default anchor tags added to each envelope recipient, and only once for the first composite template? Confusing!
	private static List<CompositeTemplate> buildCompositeTemplates(
		final List<Document> documents,
		final List<Recipient> recipients,
		final Boolean includeDefaultAnchorTags,
		final Map<String, Blob> documentContent,
		final List<CustomField> customFields,
		final Entity source) {

		List<CompositeTemplate> compositeTemplates = null;
		if (documents != null) {
			compositeTemplates = new List<CompositeTemplate>();
			Integer sequence = 1;
			Boolean addTags = includeDefaultAnchorTags;
			for (Document d : documents) {
				// FIXME: All recipients should not be added to every document in every case.
				compositeTemplates.add(new CompositeTemplate(
					d,
					sequence++,
					recipients,
					addTags,
					documentContent,
					customFields, source));
				addTags = false;
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
			} else if (!isHtml(d) && fetchDocuments && !Salesforce.isCommunitySite) { // content is SFDC document ID
				result.put(d.sourceId, Blob.valueOf(d.sourceId));
			} else { // content is SFDC document bytes -- build source map for later
				Entity source = new Entity(d.sourceId);
				if (sourceMap.containsKey(source.type)) {
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
		public EnvelopeAPI.CustomFields customFields;
		public List<EnvelopeAPI.APIDocument> documents;
		public EnvelopeAPI.Recipients recipients;
		public List<EnvelopeAPI.CompositeTemplate> compositeTemplates;
		public String emailBlurb;
		public String emailSubject;
		public EnvelopeAPI.EnvelopeNotification notification;
		public EnvelopeAPI.DefaultAnchorTags tabs;
		public String completedDateTime;
		public String declinedDateTime;
		public String sentDateTime;
		public String voidedDateTime;
		public String voidedReason;

		public APIEnvelope(
			final Envelope e,
			final Boolean send,
			final Boolean includeDefaultAnchorTags,
			final Boolean fetchDocuments,
			final Boolean useAccountNotificationDefaults) {

			if (e != null) {
				this.status = send ? 'sent' : 'created';
				this.transactionId = e.id;
				this.emailBlurb = e.emailMessage;
				this.emailSubject = e.emailSubject;
				this.notification = new EnvelopeNotification(e.notifications, useAccountNotificationDefaults);

				Map<String, Blob> documentContent =
					e.hasDocuments ? getDocumentContent(e.documents, fetchDocuments) : null;
				if (e.hasTemplates) {
					this.compositeTemplates = buildCompositeTemplates(e.documents, e.recipients,
						includeDefaultAnchorTags, documentContent, e.customFields, e.source);
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
						this.recipients = new Recipients(e.recipients, null, includeDefaultAnchorTags);
					}
					this.customFields = buildCustomFields(e.customFields, e.source);
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

		public Envelope.Status toExternalForm() {
			Datetime sent = StringUtils.parseDatetime(this.sentDateTime);
			return new Envelope.Status(
				null, // id
				null, // source
				UUID.parse(this.envelopeId),
				this.status == null ? null : this.status.toLowerCase(),
				UserInfo.getName(),
				UserInfo.getUserEmail(),
				this.recipients == null ? null : this.recipients.toExternalForm(),
				sent,
				sent != null
					&& this.notification != null
					&& this.notification.expirations != null
					&& String.isNotBlank(this.notification.expirations.expireAfter)
					? sent.addDays(Integer.valueOf(this.notification.expirations.expireAfter)) : null,
				getCompletedDatetime(),
				this.emailSubject,
				this.voidedReason,
				Datetime.now());
		}
	}

	private class EnvelopeResponse {
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
		final Envelope.Options options,
		final String senderToken) {

		return this.createEnvelope(envelope, options, senderToken, RestAPI.defaultTimeout);
	}

	public UUID createEnvelope(
		final Envelope envelope,
		final Envelope.Options options,
		final String senderToken,
		final Integer timeout) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		RestAPI.Response response = this.post(
			getBaseUrl(),
			new List<Object> { 'envelopes' },
			options == null || !options.sendNow ? new QueryString('merge_roles_on_draft', 'true') : QueryString.empty,
			getCreateHeaders(senderToken),
			JSON.serialize(new EnvelopeAPI.APIEnvelope(
				envelope,
				options != null && options.sendNow,
				options != null && options.includeDefaultAnchorTabs,
				options != null && options.fetchDocuments,
				options != null && options.useAccountNotificationDefaults),
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
		return UUID.parse(((EnvelopeResponse)JSON.deserialize(response.body, EnvelopeResponse.class)).envelopeId);
	}

	@TestVisible
	private class VoidRequest {
		public String status;
		public String voidedReason;

		public VoidRequest(final String reason) {
			this.status = 'voided';
			this.voidedReason = reason;
		}
	}

	public Boolean voidEnvelope(final UUID envelopeId, final String reason) {
		return this.voidEnvelope(envelopeId, reason, RestAPI.defaultTimeout);
	}

	public Boolean voidEnvelope(final UUID envelopeId, final String reason, final Integer timeout) {
		final RestAPI.Response response = this.put(
			new List<Object> { 'envelopes', envelopeId },
			JSON.serialize(new VoidRequest(reason)),
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

	public Envelope.Status getEnvelopeStatus(final UUID envelopeId, final Boolean includeRecipients) {
		return getEnvelopeStatus(envelopeId, includeRecipients, RestAPI.defaultTimeout);
	}

	public Envelope.Status getEnvelopeStatus(final UUID envelopeId, final Boolean includeRecipients,
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
		return ((APIEnvelope)JSON.deserialize(response.body, APIEnvelope.class)).toExternalForm();
	}
}
