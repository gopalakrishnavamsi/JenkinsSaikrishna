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

	public enum ClickAction {
		Prepare, Tag, Send
	}

	public class VisibilitySettings {

		public Boolean showTagButton { get; private set; } // STB
		public Boolean showSendButton { get; private set; } // SSB
		public Boolean showEmailSubject { get; private set; } // SES
		public Boolean showEmailMessage { get; private set; } // SEM
		public Boolean showRemindExpire { get; private set; } // SRS
		public Boolean showChatter { get; private set; } // SCS
		public Boolean showAddFile { get; private set; } // SAF

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

	public class CustomRecipient {

		public String email { get; private set; }
		public String firstName { get; private set; }
		public String lastName { get; private set; }
		public String type { get; private set; }
		public String role { get; private set; }
		public Integer routingOrder { get; private set; }
		public String accessCode { get; private set; }
		public String note { get; private set; }
		public String inPersonSigner { get; private set; }
		public String signingGroupName { get; private set; }
		public Boolean isSigningGroup { get; private set; }
		public String smsPhoneNumber { get; private set; }
		public Boolean signNow { get; private set; }
		public List<String> parseErrors { get; private set; }
		public String name { get; private set; }

		// CRL constructor
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
			this.parseErrors = parseErrors;
			this.isSigningGroup = String.isNotBlank(signingGroupName);
			this.signNow = signNow;
			this.name = StringUtils.mkName(firstName, lastName);
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

	public class RelatedContacts {

		public Map<String, String> fieldMap { get; private set; }
		public String relationship { get; private set; }
		public Boolean addSourceRecipients { get; private set; }
		public List<String> parseErrors { get; private set; }
		public Boolean isSigningGroup { get; private set; }
		public Boolean isSignInPerson { get; private set; }

		public RelatedContacts(final Map<String, String> fieldMap, final String relationship,
			final Boolean addSourceRecipients, final List<String> parseErrors) {

			this.fieldMap = fieldMap == null ? new Map<String, String>() : fieldMap;
			this.relationship = relationship;
			this.addSourceRecipients = addSourceRecipients;
			this.parseErrors = parseErrors;
			this.isSigningGroup = this.fieldMap.containsKey(KEY_SIGNING_GROUP);
			this.isSignInPerson = this.fieldMap.containsKey(KEY_SIGN_IN_PERSON);
		}
	}

	public class RecipientType {

		public String type { get; private set; }
		public Boolean signNow { get; private set; }

		public RecipientType(final String type, final Boolean signNow) {
			this.type = String.isBlank(type) ? Recipient.TYPE_SIGNER : type.trim();
			this.signNow = signNow == true && SIGN_NOW_TYPES.contains(this.type.toLowerCase());
		}
	}

	public class RecipientRoleType {

		public String role { get; private set; }
		public RecipientType type { get; private set; }

		public RecipientRoleType(final String role, final RecipientType type) {
			this.role = role;
			this.type = type;
		}
	}

	public class RecipientSettings {

		public List<RelatedContacts> relatedContacts { get; private set; } // CRCL
		public List<CustomRecipient> recipients { get; private set; } // CRL
		public Boolean addSourceRecipients { get; private set; }
		public Integer recipientLimit { get; private set; } // RSL
		public Boolean sequentialRoutingOrder { get; private set; } // RROS
		public Integer startingRoutingOrder { get; private set; } // RSRO
		public List<RecipientRoleType> recipientRoleTypes { get; private set; } // RT
		public Map<String, String> roleToTemplateRoles { get; private set; } // CCRM
		public Map<String, RecipientType> roleToRecipientTypes { get; private set; } // CCTM
		public Map<String, String> roleToNotes { get; private set; } // CCNM
		public Boolean hasRelatedContacts {
			get {
				return Collection.isNotEmpty(this.relatedContacts);
			}
		}
		public Boolean hasRecipients {
			get {
				return Collection.isNotEmpty(this.recipients);
			}
		}

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

	public class DocumentSettings {

		public Boolean addSourceDocuments { get; private set; } // LA/LF
		public Set<UUID> templateIds { get; private set; } // DST
		public Set<Id> fileIds { get; private set; } // RC
		public Boolean hasTemplates {
			get {
				return this.templateIds != null && !this.templateIds.isEmpty();
			}
		}

		public DocumentSettings(final Boolean addSourceDocuments, final Set<UUID> templateIds, final Set<Id> fileIds) {
			this.addSourceDocuments = addSourceDocuments;
			this.templateIds = templateIds;
			this.fileIds = fileIds;
		}
	}

	public Exception error { get; private set; }
	public Id id { get; private set; }
	public Entity source { get; private set; }
	public ClickAction action { get; private set; } // OCO
	public VisibilitySettings visibility { get; private set; }
	public Envelope.Notifications notifications { get; private set; } // RES
	public Recipient.EmailSettings email { get; private set; } // CES, CEM, CEL
	public DocumentSettings documents { get; private set; }
	public RecipientSettings recipients { get; private set; }
	public Boolean hasRecipients {
		get {
			// Return true if CRL or CRCL is specified.
			return this.recipients != null && (this.recipients.hasRelatedContacts || this.recipients.hasRecipients);
		}
	}
	public Boolean hasTemplates {
		get {
			return this.documents != null && this.documents.hasTemplates;
		}
	}
	public Boolean hasError {
		get {
			return this.error != null;
		}
	}

	public EnvelopeConfiguration(final Exception ex) {
		this.error = ex;
	}

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
