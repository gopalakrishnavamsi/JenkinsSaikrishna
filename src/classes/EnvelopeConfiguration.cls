/**
 * A DocuSign for Salesforce envelope configuration (formerly custom button).
 */
public with sharing class EnvelopeConfiguration {

	public static final String DEFAULT_NOTE = 'DEFAULT_NOTE';
	public static final String KEY_SIGNING_GROUP = 'signinggroup';
	public static final String KEY_EMAIL = 'email';
	public static final String KEY_FIRST_NAME = 'firstname';
	public static final String KEY_LAST_NAME = 'lastname';
	public static final String KEY_ROLE = 'role';
	public static final String KEY_SIGN_IN_PERSON = 'signinpersonname';
	public static final String KEY_ROUTING_ORDER = 'routingorder';
	public static final String KEY_ACCESS_CODE = 'accesscode';
	public static final String KEY_NOTE = 'recipientnote';
	public static final String KEY_SIGN_NOW = 'signnow';
	public static final String KEY_LOAD_DEFAULT_CONTACTS = 'loaddefaultcontacts';
	public static final String KEY_SMS = 'smsauthphone';
	public static final String KEY_CUSTOM_PREFIX = '__custom_';
	public static final Set<String> VALID_RECIPIENT_KEYS = new Set<String> {
		KEY_SIGNING_GROUP, KEY_EMAIL, KEY_FIRST_NAME, KEY_LAST_NAME, KEY_ROLE, KEY_LOAD_DEFAULT_CONTACTS,
		KEY_SIGN_IN_PERSON, KEY_ROUTING_ORDER, KEY_ACCESS_CODE, KEY_NOTE, KEY_SIGN_NOW, KEY_SMS
	};
	private static final Set<String> SIGN_NOW_TYPES = new Set<String> {
		Recipient.TYPE_SIGNER.toLowerCase(), Recipient.TYPE_IN_PERSON_SIGNER.toLowerCase()
	};

	/**
	 * What action to perform after a custom button is clicked:
	 * <ul>
	 *     <li><code>Prepare</code>: Prepare the envelope. Add or remove documents and recipients and set email and
	 *     notification options.</li>
	 *     <li><code>Tag</code>: Bypass DocuSign for Salesforce envelope preparation and go to the DocuSign tagger.</li>
	 *     <li><code>Send</code>: Bypass DocuSign for Salesforce envelope preparation and the DocuSign tagger, and
	 *     immediately send the envelope.</li>
	 * </ul>
	 */
	public enum ClickAction {
		Prepare, Tag, Send
	}

	/**
	 * DocuSign for Salesforce envelope preparation UI element visibility settings.
	 */
	public class VisibilitySettings {
		/**
		 * Whether or not to show the tag/next button (STB).
		 */
		public Boolean showTagButton { get; private set; }
		/**
		 * Whether or not to show the send now button (SSB).
		 */
		public Boolean showSendButton { get; private set; }
		/**
		 * Whether or not to show the email subject (SES).
		 */
		public Boolean showEmailSubject { get; private set; }
		/**
		 * Whether or not to show the email message (SEM).
		 */
		public Boolean showEmailMessage { get; private set; }
		/**
		 * Whether or not to show the remind and expire settings (SRS).
		 */
		public Boolean showRemindExpire { get; private set; }
		/**
		 * Whether or not to show the Chatter notification settings (SCS).
		 */
		public Boolean showChatter { get; private set; }
		/**
		 * Whether or not to show the add file option (SAF).
		 */
		public Boolean showAddFile { get; private set; }

		/**
		 * Constructs visibility settings.
		 *
		 * @param showTagButton Whether or not to show the tag/next button.
		 * @param showSendButton Whether or not to show the send now button.
		 * @param showEmailSubject Whether or not to show the email subject.
		 * @param showEmailMessage Whether or not to show the email message.
		 * @param showRemindExpire Whether or not to show the remind and expire settings.
		 * @param showChatter Whether or not to show Chatter notification settings.
		 * @param showAddFile Whether or not to show the add file option.
		 */
		public VisibilitySettings(final Boolean showTagButton, final Boolean showSendButton,
			final Boolean showEmailSubject, final Boolean showEmailMessage, final Boolean showRemindExpire,
			final Boolean showChatter, final Boolean showAddFile) {

			this.showTagButton = showTagButton;
			this.showSendButton = showSendButton;
			this.showEmailSubject = showEmailSubject;
			this.showEmailMessage = showEmailMessage;
			this.showRemindExpire = showRemindExpire;
			this.showChatter = showChatter;
			this.showAddFile = showAddFile;
		}

		/**
		 * Converts the visibility settings to query string parameters.
		 *
		 * @return The query string parameters for visibility settings.
		 */
		public Map<String, String> toParameters() {
			// Possible for parameters to be null and not included in query string.
			Map<String, String> parameters = new Map<String, String>();
			if (showTagButton != null) parameters.put('STB', showTagButton ? '1' : '0');
			if (showSendButton != null) parameters.put('SSB', showSendButton ? '1' : '0');
			if (showEmailSubject != null) parameters.put('SES', showEmailSubject ? '1' : '0');
			if (showEmailMessage != null) parameters.put('SEM', showEmailMessage ? '1' : '0');
			if (showRemindExpire != null) parameters.put('SRS', showRemindExpire ? '1' : '0');
			if (showChatter != null) parameters.put('SCS', showChatter ? '1' : '0');
			if (showAddFile != null) parameters.put('SAF', showAddFile ? '1' : '0');
			return parameters;
		}
	}

	/**
	 * A custom envelope recipient.
	 */
	public class CustomRecipient {
		/**
		 * The recipient's email address.
		 */
		public String email { get; private set; }
		/**
		 * The recipient's first name.
		 */
		public String firstName { get; private set; }
		/**
		 * The recipient's last name.
		 */
		public String lastName { get; private set; }
		/**
		 * Read-only property of the recipient's full name.
		 */
		public String name {
			get {
				return StringUtils.mkName(this.firstName, this.lastName);
			}
		}
		/**
		 * The recipient type.
		 */
		public String type { get; private set; }
		/**
		 * The recipient role name.
		 */
		public String role { get; private set; }
		/**
		 * The recipient routing order.
		 */
		public Integer routingOrder { get; private set; }
		/**
		 * The recipient authentication access code.
		 */
		public String accessCode { get; private set; }
		/**
		 * The phone number used for SMS authentication.
		 */
		public String smsPhoneNumber { get; private set; }
		/**
		 * The private note sent to the recipient.
		 */
		public String note { get; private set; }
		/**
		 * The in-person signer's name.
		 */
		public String inPersonSigner { get; private set; }
		/**
		 * The DocuSign signing group name.
		 */
		public String signingGroupName { get; private set; }
		/**
		 * Read-only property indicating whether this recipient is a DocuSign signing group.
		 */
		public Boolean isSigningGroup {
			get {
				return String.isNotBlank(this.signingGroupName);
			}
		}
		/**
		 * Whether or not the recipient should sign now.
		 */
		public Boolean signNow { get; private set; }
		/**
		 * Accumulated parsing errors.
		 */
		public List<String> parseErrors { get; private set; }

		/**
		 * Constructs a custom envelope recipient.
		 *
		 * @param email The recipient's email address.
		 * @param firstName The recipient's first name.
		 * @param lastName The recipient's last name.
		 * @param type The recipient type.
		 * @param role The recipient role name.
		 * @param routingOrder The recipient routing order.
		 * @param accessCode The recipient authentication access code.
		 * @param smsPhoneNumber The phone number used for SMS authentication.
		 * @param note The private note sent to the recipient.
		 * @param inPersonSigner The in-person signer's name.
		 * @param signingGroupName The DocuSign signing group name.
		 * @param signNow Whether or not the recipient should sign now.
		 * @param parseErrors Accumulated parsing errors.
		 */
		public CustomRecipient(final String email, final String firstName, final String lastName, final String type,
			final String role, final Integer routingOrder, final String accessCode, final String smsPhoneNumber,
			final String note, final String inPersonSigner, final String signingGroupName, final Boolean signNow,
			final List<String> parseErrors) {

			this.email = email;
			this.firstName = firstName;
			this.lastName = lastName;
			this.type = type;
			this.role = role;
			this.routingOrder = routingOrder;
			this.accessCode = accessCode;
			this.smsPhoneNumber = smsPhoneNumber;
			this.note = note;
			this.inPersonSigner = inPersonSigner;
			this.signingGroupName = signingGroupName;
			this.signNow = signNow;
			this.parseErrors = parseErrors;
		}

		private Recipient.Authentication getAuthentication() {
			Recipient.Authentication result = null;
			Boolean useSms = String.isNotBlank(this.smsPhoneNumber);
			if (String.isNotBlank(this.accessCode) || String.isNotBlank(this.smsPhoneNumber)) {
				result = new Recipient.Authentication(this.accessCode, useSms,
					useSms ? new List<String> { this.smsPhoneNumber } : null);
			}
			return result;
		}

		/**
		 * Converts the custom recipient to a DocuSign envelope recipient.
		 *
		 * @param signingGroups Map of signing group names to signing groups.
		 *
		 * @return The DocuSign envelope recipient.
		 */
		public Recipient toRecipient(final Map<String, Recipient.SigningGroup> signingGroups) {
			Recipient result = null;
			if (this.isSigningGroup) {
				result = Recipient.fromSigningGroup(
					this.routingOrder == null ? 1 : this.routingOrder,
					String.isBlank(this.role) ? null : new Recipient.Role(this.role, null),
					signingGroups.get(this.signingGroupName.toLowerCase()),
					getAuthentication(),
					this.note);
			} else if (String.isNotBlank(inPersonSigner)) {
				result = Recipient.newInPersonSigner(
					this.routingOrder == null ? 1 : this.routingOrder,
					String.isBlank(this.role) ? null : new Recipient.Role(this.role, null),
					this.inPersonSigner,
					this.email,
					this.name,
					this.email,
					getAuthentication(),
					this.note,
					this.signNow);
			} else {
				result = Recipient.newRecipient(
					this.routingOrder == null ? 1 : this.routingOrder,
					String.isBlank(this.type) ? Recipient.TYPE_SIGNER : this.type,
					String.isBlank(this.role) ? null : new Recipient.Role(this.role, null),
					this.name,
					this.email,
					getAuthentication(),
					this.note,
					this.signNow);
			}
			return result;
		}
	}

	/**
	 * Salesforce contacts pulled from a related list.
	 */
	public class RelatedContacts {
		/**
		 * Mapping of custom recipient parameters to object field names.
		 */
		public Map<String, String> fieldMap { get; private set; }
		/**
		 * The relationship name on the parent Salesforce object.
		 */
		public String relationship { get; private set; }
		/**
		 * Accumulated parsing errors.
		 */
		public List<String> parseErrors { get; private set; }
		/**
		 * Read-only property indicating whether the related contact may be a DocuSign signing group.
		 */
		public Boolean isSigningGroup {
			get {
				return this.fieldMap != null && this.fieldMap.containsKey(KEY_SIGNING_GROUP);
			}
		}
		/**
		 * Read-only property indicating whether the related contact may be an in-person signer.
		 */
		public Boolean isSignInPerson {
			get {
				return this.fieldMap != null && this.fieldMap.containsKey(KEY_SIGN_IN_PERSON);
			}
		}

		/**
		 * Constructs Salesforce related contacts.
		 *
		 * @param fieldMap Mapping of custom recipient parameters to object field names.
		 * @param relationship The relationship name on the parent Salesforce object.
		 * @param parseErrors Accumulated parsing errors.
		 */
		public RelatedContacts(final Map<String, String> fieldMap, final String relationship,
			final List<String> parseErrors) {

			this.fieldMap = fieldMap == null ? new Map<String, String>() : fieldMap;
			this.relationship = relationship;
			this.parseErrors = parseErrors;
		}
	}

	/**
	 * A DocuSign envelope recipient type.
	 */
	public class RecipientType {
		/**
		 * The recipient type.
		 */
		public String type { get; private set; }
		/**
		 * Whether or not the recipient should sign now.
		 */
		public Boolean signNow { get; private set; }

		/**
		 * Constructs a DocuSign envelope recipient type.
		 *
		 * @param type The recipient type.
		 * @param signNow Whether or not the recipient should sign now.
		 */
		public RecipientType(final String type, final Boolean signNow) {
			this.type = String.isBlank(type) ? Recipient.TYPE_SIGNER : type.trim();
			this.signNow = signNow == true && SIGN_NOW_TYPES.contains(this.type.toLowerCase());
		}
	}

	/**
	 * A mapping of DocuSign envelope recipient role to type.
	 */
	public class RecipientRoleType {
		/**
		 * The recipient role name.
		 */
		public String role { get; private set; }
		/**
		 * The recipient type.
		 */
		public RecipientType type { get; private set; }

		/**
		 * Constructs a recipient role type.
		 *
		 * @param role The recipient role name.
		 * @param type The recipient type.
		 */
		public RecipientRoleType(final String role, final RecipientType type) {
			this.role = role;
			this.type = type;
		}
	}

	/**
	 * Container class for DocuSign envelope recipient-related settings.
	 */
	public class RecipientSettings {
		/**
		 * Salesforce contacts to be pulled from related lists (CRCL).
		 */
		public List<RelatedContacts> relatedContacts { get; private set; }
		/**
		 * Custom recipients (CRL).
		 */
		public List<CustomRecipient> recipients { get; private set; }
		/**
		 * Whether or not to automatically add default source recipients (LSR).
		 */
		public Boolean addSourceRecipients { get; private set; }
		/**
		 * Maximum number of recipients (RSL).
		 */
		public Integer recipientLimit { get; private set; }
		/**
		 * Whether or not to assign sequential routing orders to recipients (RROS).
		 */
		public Boolean sequentialRoutingOrder { get; private set; }
		/**
		 * The starting recipient routing order (RSRO).
		 */
		public Integer startingRoutingOrder { get; private set; }
		/**
		 * Mapping of recipient roles to types (RT).
		 */
		public List<RecipientRoleType> recipientRoleTypes { get; private set; }
		/**
		 * Mapping of Salesforce roles to DocuSign template roles (CCRM).
		 */
		public Map<String, String> roleToTemplateRoles { get; private set; }
		/**
		 * Mapping of Salesforce roles to DocuSign recipient types (CCTM).
		 */
		public Map<String, RecipientType> roleToRecipientTypes { get; private set; }
		/**
		 * Mapping of Salesforce roles to private recipient notes (CCNM).
		 */
		public Map<String, String> roleToNotes { get; private set; }
		/**
		 * Read-only property indicating whether related contacts are present.
		 */
		public Boolean hasRelatedContacts {
			get {
				return Collection.isNotEmpty(this.relatedContacts);
			}
		}
		/**
		 * Read-only property indicating whether custom recipients are present.
		 */
		public Boolean hasRecipients {
			get {
				return Collection.isNotEmpty(this.recipients);
			}
		}

		/**
		 * Constructs recipient settings.
		 *
		 * @param relatedContacts Salesforce contacts to be pulled from related lists.
		 * @param recipients Custom recipients.
		 * @param addSourceRecipients Whether or not to automatically add default source recipients.
		 * @param recipientLimit Maximum number of recipients.
		 * @param sequentialRoutingOrder Whether or not to assign sequential routing orders to recipients.
		 * @param startingRoutingOrder The starting recipient routing order
		 * @param recipientRoleTypes Mapping of recipient roles to types.
		 * @param roleToTemplateRoles Mapping of Salesforce roles to DocuSign template roles.
		 * @param roleToRecipientTypes Mapping of Salesforce roles to DocuSign recipient types.
		 * @param roleToNotes Mapping of Salesforce roles to private recipient notes.
		 */
		public RecipientSettings(
			final List<RelatedContacts> relatedContacts,
			final List<CustomRecipient> recipients,
			final Boolean addSourceRecipients,
			final Integer recipientLimit,
			final Boolean sequentialRoutingOrder,
			final Integer startingRoutingOrder,
			final List<RecipientRoleType> recipientRoleTypes,
			final Map<String, String> roleToTemplateRoles,
			final Map<String, RecipientType> roleToRecipientTypes,
			final Map<String, String> roleToNotes) {

			this.relatedContacts = relatedContacts;
			this.recipients = recipients;
			this.addSourceRecipients = addSourceRecipients;
			this.recipientLimit = recipientLimit;
			this.sequentialRoutingOrder = sequentialRoutingOrder;
			this.startingRoutingOrder = startingRoutingOrder >= 1 ? startingRoutingOrder : 1;
			this.recipientRoleTypes = recipientRoleTypes;
			this.roleToTemplateRoles = roleToTemplateRoles;
			this.roleToRecipientTypes = roleToRecipientTypes;
			this.roleToNotes = roleToNotes;
		}
	}

	/**
	 * Container class for DocuSign envelope document-related settings.
	 */
	public class DocumentSettings {
		/**
		 * Whether or not to automatically add Salesforce source documents to the envelope (LF).
		 */
		public Boolean addSourceDocuments { get; private set; }
		/**
		 * Whether or not to add only the last updated linked file to the envelope (MRL). Ignored if
		 * <code>addSourceDocuments<code> is <code>false</code>.
		 */
		public Boolean addLastUpdatedOnly { get; private set; }
		/**
		 * DocuSign template IDs (DST).
		 */
		public Set<UUID> templateIds { get; private set; }
		/**
		 * File IDs to add to the envelope (FILES).
		 */
		public Set<Id> fileIds { get; private set; }
		/**
		 * Read-only property indicating whether DocuSign templates are present.
		 */
		public Boolean hasTemplates {
			get {
				return this.templateIds != null && !this.templateIds.isEmpty();
			}
		}

		/**
		 * Constructs document settings.
		 *
		 * @param addSourceDocuments Whether or not to automatically add Salesforce source documents to the envelope.
		 * @param addLastUpdatedOnly Whether or not to add only the last updated linked file to the envelope.
		 * @param templateIds DocuSign template IDs.
		 * @param fileIds File IDs to add to the envelope.
		 */
		public DocumentSettings(final Boolean addSourceDocuments, final Boolean addLastUpdatedOnly,
			final Set<UUID> templateIds, final Set<Id> fileIds) {

			this.addSourceDocuments = addSourceDocuments;
			this.addLastUpdatedOnly = addLastUpdatedOnly;
			this.templateIds = templateIds;
			this.fileIds = fileIds;
		}
	}

	/**
	 * The error encountered while constructing the envelope configuration.
	 */
	public Exception error { get; private set; }
	/**
	 * The ID of the associated EnvelopeConfiguration__c record.
	 */
	public Id id { get; private set; }
	/**
	 * The Salesforce source object (derived from sId).
	 */
	public Entity source { get; private set; }
	/**
	 * The action to take upon creating an envelope based on the envelope configuration (OCO).
	 */
	public ClickAction action { get; private set; }
	/**
	 * Settings that control DocuSign for Salesforce envelope preparation UI element visibility.
	 */
	public VisibilitySettings visibility { get; private set; }
	/**
	 * Envelope notification settings (RES).
	 */
	public Envelope.Notifications notifications { get; private set; }
	/**
	 * Recipient email settings (CES, CEM, CEL).
	 */
	public Recipient.EmailSettings email { get; private set; }
	/**
	 * Document-related settings.
	 */
	public DocumentSettings documents { get; private set; }
	/**
	 * Recipient-related settings.
	 */
	public RecipientSettings recipients { get; private set; }
	/**
	 * Read-only property indicating whether any custom or related recipients are defined in the envelope configuration.
	 */
	public Boolean hasRecipients {
		get {
			// Return true if CRL or CRCL is specified.
			return this.recipients != null && (this.recipients.hasRelatedContacts || this.recipients.hasRecipients);
		}
	}
	/**
	 * Read-only property indicating whether any DocuSign templates are defined in the envelope configuration.
	 */
	public Boolean hasTemplates {
		get {
			return this.documents != null && this.documents.hasTemplates;
		}
	}
	/**
	 * Read-only property indicating whether an error was encountered while processing the envelope configuration.
	 */
	public Boolean hasError {
		get {
			return this.error != null;
		}
	}

	/**
	 * Constructs a DocuSign envelope configuration from an exception.
	 *
	 * @param ex The exception encountered while processing the envelope configuration.
	 */
	public EnvelopeConfiguration(final Exception ex) {
		this.error = ex;
	}

	/**
	 * Constructs a DocuSign envelope configuration.
	 *
	 * @param id The ID of the associated EnvelopeConfiguration__c record.
	 * @param source The Salesforce source object.
	 * @param action The action to take upon creating an envelope based on the envelope configuration.
	 * @param visibility Settings that control DocuSign for Salesforce envelope preparation UI element visibility.
	 * @param notifications Envelope notification settings.
	 * @param email Recipient email settings.
	 * @param documents Document-related settings.
	 * @param recipients Recipient-related settings.
	 */
	public EnvelopeConfiguration(
		final Id id,
		final Entity source,
		final ClickAction action,
		final VisibilitySettings visibility,
		final Envelope.Notifications notifications,
		final Recipient.EmailSettings email,
		final DocumentSettings documents,
		final RecipientSettings recipients) {

		this.id = id;
		this.source = source;
		this.action = action;
		this.visibility = visibility;
		this.notifications = notifications;
		this.email = email;
		this.documents = documents;
		this.recipients = recipients;
	}
}
