/**
 * Representation of a DocuSign envelope recipient.
 */
global class Recipient implements Comparable {
	/**
	 * Signer (Needs to Sign) recipient type constant.
	 */
	global static final String TYPE_SIGNER = 'Signer';
	/**
	 * In person signer recipient type constant.
	 */
	global static final String TYPE_IN_PERSON_SIGNER = 'InPersonSigner';
	/**
	 * Embedded signer recipient type constant.
	 */
	global static final String TYPE_EMBEDDED_SIGNER = 'EmbeddedSigner';
	/**
	 * Carbon copy (Receives a Copy) recipient type constant.
	 */
	global static final String TYPE_CARBON_COPY = 'CarbonCopy';
	/**
	 * Certified delivery (Needs to View) recipient type constant.
	 */
	global static final String TYPE_CERTIFIED_DELIVERY = 'CertifiedDelivery';
	/**
	 * Agent (Specify Recipients) recipient type constant.
	 */
	global static final String TYPE_AGENT = 'Agent';
	/**
	 * Editor (Allow to Edit) recipient type constant.
	 */
	global static final String TYPE_EDITOR = 'Editor';
	/**
	 * Intermediary (Update Recipients) recipient type constant.
	 */
	global static final String TYPE_INTERMEDIARY = 'Intermediary';
	/**
	 * Created status constant.
	 */
	global static final String STATUS_CREATED = 'created';
	/**
	 * Sent status constant.
	 */
	global static final String STATUS_SENT = 'sent';
	/**
	 * Delivered status constant.
	 */
	global static final String STATUS_DELIVERED = 'delivered';
	/**
	 * Declined status constant.
	 */
	global static final String STATUS_DECLINED = 'declined';
	/**
	 * Completed status constant.
	 */
	global static final String STATUS_COMPLETED = 'completed';
	/**
	 * Signed status constant.
	 */
	global static final String STATUS_SIGNED = 'signed';
	/**
	 * Canceled status constant.
	 */
	global static final String STATUS_CANCELED = 'canceled';

	/**
	 * The ID of the associated Recipient__c record.
	 */
	@AuraEnabled
	global Id id { get; private set; }
	/**
	 * The type of the recipient.
	 */
	@AuraEnabled
	global String type { get; private set; }
	/**
	 * The ordinal sequence of the recipient as displayed on the DocuSign envelope.
	 */
	@AuraEnabled
	global Integer sequence { get; private set; }
	/**
	 * The routing order of the recipient. This is distinct from <code>sequence</code> and need not be unique across an envelope's recipients.
	 */
	@AuraEnabled
	global Integer routingOrder { get; private set; }
	/**
	 * The role of the recipient. Used to tie the recipient to DocuSign template roles or for use with automatic anchor tags.
	 */
	@AuraEnabled
	global Role role { get; private set; }
	/**
	 * The name of the recipient.
	 */
	@AuraEnabled
	global String name { get; private set; }
	/**
	 * The email of the recipient.
	 */
	@AuraEnabled
	global String email { get; private set; }
	/**
	 * The DocuSign signing group.
	 */
	@AuraEnabled
	global SigningGroup signingGroup { get; private set; }
	/**
	 * The phone number of the recipient. Can be used for SMS authentication.
	 */
	@AuraEnabled
	global String phone { get; private set; }
	/**
	 * The recipient authentication options.
	 */
	@AuraEnabled
	global Authentication authentication { get; private set; }
	/**
	 * The private note sent to the recipient.
	 */
	@AuraEnabled
	global String note { get; private set; }
	/**
	 * The email settings for the recipient.
	 */
	@AuraEnabled
	global EmailSettings emailSettings { get; private set; }
	/**
	 * The host name of the recipient. Used only for in-person signing.
	 */
	@AuraEnabled
	global String hostName { get; private set; }
	/**
	 * The host email of the recipient. Used only for in-person signing.
	 */
	@AuraEnabled
	global String hostEmail { get; private set; }
	/**
	 * Whether the recipient should sign now. Honored only for in-person signing or when the first signer is the current user.
	 */
	@AuraEnabled
	global Boolean signNow { get; private set; }
	/**
	 * The Salesforce source object for the recipient (Contact, Lead, or User).
	 */
	@AuraEnabled
	global Entity source { get; private set; }
	/**
	 * Read-only property indicating whether the recipient is a signing group.
	 */
	@AuraEnabled
	global Boolean isSigningGroup {
		get {
			return this.signingGroup != null;
		}
	}
	/**
	 * Whether this recipient may be modified. Used with DocuSign templates.
	 */
	@AuraEnabled
	global Boolean readOnly { get; private set; }
	/**
	 * Whether this recipient is required. Used with DocuSign templates.
	 */
	@AuraEnabled
	global Boolean required { get; private set; }

	/**
	 * Constructs a DocuSign envelope recipient.
	 *
	 * @param id The ID of the associated Recipient__c record.
	 * @param type The type of recipient.
	 * @param sequence The ordinal sequence of the recipient.
	 * @param routingOrder The routing order of the recipient.
	 * @param role The recipient role.
	 * @param name The name of the recipient.
	 * @param email The email of the recipient.
	 * @param signingGroup The DocuSign signing group.
	 * @param phone The phone number of the recipient.
	 * @param authentication Optional authentication method for the recipient.
	 * @param note Optional private note sent to the recipient.
	 * @param emailSettings The email settings for the recipient.
	 * @param hostName The host name of the recipient, used for in-person signing.
	 * @param hostEmail The host email of the recipient, used for in-person signing.
	 * @param signNow Whether the recipient should sign now.
	 * @param source The Salesforce source object for the recipient.
	 * @param readOnly Whether this recipient may be modified. Used with DocuSign templates.
	 * @param required Whether this recipient is required. Used with DocuSign templates.
	 */
	global Recipient(
		final Id id,
		final String type,
		final Integer sequence,
		final Integer routingOrder,
		final Role role,
		final String name,
		final String email,
		final SigningGroup signingGroup,
		final String phone,
		final Authentication authentication,
		final String note,
		final EmailSettings emailSettings,
		final String hostName,
		final String hostEmail,
		final Boolean signNow,
		final Entity source,
		final Boolean readOnly,
		final Boolean required) {

		this.id = id;
		this.type = type;
		this.sequence = sequence;
		this.routingOrder = routingOrder == null || routingOrder <= 0 ? 1 : routingOrder;
		this.role = role;
		this.name = name;
		this.email = email;
		this.signingGroup = signingGroup;
		this.phone = phone;
		this.authentication = authentication;
		this.note = note;
		this.emailSettings = emailSettings;
		this.hostName = hostName;
		this.hostEmail = hostEmail;
		this.signNow = signNow;
		this.source = source;
		this.readOnly = readOnly;
		this.required = required;
	}

	/**
	 * Factory method to construct a DocuSign signing group recipient.
	 *
	 * @param routingOrder The routing order for the recipient.
	 * @param role The recipient role.
	 * @param signingGroup The DocuSign signing group.
	 * @param authentication Optional recipient authentication methods.
	 * @param note Optional private note for the recipient.
	 *
	 * @return The DocuSign signing group recipient.
	 */
	public static Recipient fromSigningGroup(
		final Integer routingOrder,
		final Role role,
		final SigningGroup signingGroup,
		final Authentication authentication,
		final String note) {

		return new Recipient(
			null,
			Recipient.TYPE_SIGNER,
			null,
			routingOrder,
			role,
			signingGroup == null ? null : signingGroup.name,
			null,
			signingGroup,
			null,
			authentication,
			note,
			null,
			null,
			null,
			false,
			null,
			false,
			false);
	}

	/**
	 * Factory method to construct an in-person signer recipient.
	 *
	 * @param routingOrder The recipient routing order.
	 * @param role The recipient role.
	 * @param name The signer name.
	 * @param email Optional signer email.
	 * @param hostName The host name.
	 * @param hostEmail The host email.
	 * @param authentication Optional recipient authentication methods.
	 * @param note Optional private note for the recipient.
	 * @param signNow Whether the recipient should sign now.
	 *
	 * @return The in-person signer recipient.
	 */
	public static Recipient newInPersonSigner(
		final Integer routingOrder,
		final Role role,
		final String name,
		final String email,
		final String hostName,
		final String hostEmail,
		final Authentication authentication,
		final String note,
		final Boolean signNow) {

		return new Recipient(
			null,
			TYPE_IN_PERSON_SIGNER,
			null,
			routingOrder,
			role,
			name,
			email,
			null,
			null,
			authentication,
			note,
			null,
			hostName,
			hostEmail,
			signNow,
			null,
			false,
			false);
	}

	/**
	 * Factory method to construct a recipient from a Salesforce source.
	 *
	 * @param name The recipient name.
	 * @param email The recipient email.
	 * @param phone The recipient phone that may be used for SMS authentication.
	 * @param role The recipient role.
	 * @param source The source Salesforce entity.
	 *
	 * @return The recipient based on the Salesforce source entity.
	 */
	global static Recipient fromSource(final String name, final String email, final String phone, final String role,
		final Entity source) {

		return new Recipient(
			null,
			TYPE_SIGNER,
			null,
			null,
			String.isBlank(role) ? null : new Role(role),
			name,
			email,
			null,
			phone,
			null,
			null,
			null,
			null,
			null,
			false,
			source,
			false,
			false);
	}

	/**
	 * Factory method to construct a basic DocuSign envelope recipient.
	 *
	 * @param routingOrder The recipient routing order.
	 * @param type The recipient type.
	 * @param role The recipient role.
	 * @param name The recipient name.
	 * @param email The recipient email.
	 * @param authentication Optional recipient authentication methods.
	 * @param note Optional private note for the recipient.
	 * @param signNow Whether the recipient should sign now. Ignored for non-signer types or when the recipient is not
	 * the current user.
	 *
	 * @return The new DocuSign envelope recipient.
	 */
	public static Recipient newRecipient(
		final Integer routingOrder,
		final String type,
		final Role role,
		final String name,
		final String email,
		final Authentication authentication,
		final String note,
		final Boolean signNow) {

		return new Recipient(
			null,
			type,
			null,
			routingOrder,
			role,
			name,
			email,
			null,
			null,
			authentication,
			note,
			null,
			null,
			null,
			signNow,
			null,
			false,
			false);
	}

	/**
	 * Factory method to create a bulk recipient placeholder for a bulk envelope draft. Currently a single signer
	 * recipient is supported with both <code>routingOrder</code> and <code>sequence</code> set to <code>1</code>.
	 *
	 * @return The new DocuSign bulk envelope placeholder recipient.
	 */
	public static Recipient newBulkRecipientPlaceholder() {
		return new Recipient(
			null,
			TYPE_SIGNER,
			1,
			1,
			null,
			UUID.randomUUID().toString(),
			UUID.randomUUID().toString() + '@place.holder',
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			false,
			null,
			false,
			false);
	}

	/**
	 * Factory method to create a bulk recipient suitable for bulk envelope copies. Currently a single signer recipient
	 * is supported with both <code>routingOrder</code> and <code>sequence</code> set to <code>1</code>.
	 *
	 * @param name The recipient name.
	 * @param email The recipient email.
	 * @param source The Salesforce source object.
	 *
	 * @return The new DocuSign bulk envelope copy recipient.
	 */
	global static Recipient newBulkRecipient(
		final String name,
		final String email,
		final Entity source) {

		return new Recipient(
			null,
			TYPE_SIGNER,
			1,
			1,
			null,
			name,
			email,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			false,
			source,
			false,
			false);
	}

	/**
	 * Creates an embedded signer recipient for the current user. This recipient is expected to sign an envelope
	 * immediately, and will not receive an email requesting signature.
	 *
	 * @return The newly-created embedded signer.
	 */
	global static Recipient newEmbeddedSigner() {
		return new Recipient(
			null,
			TYPE_EMBEDDED_SIGNER,
			1,
			1,
			new Role('Signer 1', 1),
			UserInfo.getName(),
			UserInfo.getUserEmail(),
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			true,
			new Entity(UserInfo.getUserId()),
			false,
			false);
	}

	/**
	 * Representation of a DocuSign envelope recipient role used for automatic anchor tags or template role
	 * matching.
	 */
	global class Role implements Comparable {
		/**
		 * The role name.
		 */
		@AuraEnabled
		global String name { get; private set; }
		/**
		 * The role ordinal used for mapping to automatic anchor tags.
		 */
		@AuraEnabled
		global Integer value { get; private set; }
		/**
		 * Read-only property describing whether this role has a valid value. If <code>true</code> (> 0),
		 * the role is mapped to automatic anchor tags.
		 */
		public Boolean hasValue {
			get {
				return this.value > 0;
			}
		}

		/**
		 * Constructs a DocuSign envelope recipient role with no value. This role will not be used for automatic
		 * anchor tags.
		 *
		 * @param name The role name.
		 */
		public Role(final String name) {
			this(name, null);
		}

		/**
		 * Constructs a DocuSign envelope recipient role.
		 *
		 * @param name The role name.
		 * @param value The role ordinal used for mapping to automatic anchor tags.
		 */
		global Role(final String name, final Integer value) {
			this.name = name;
			this.value = value;
		}

		/**
		 * Used to sort roles by ascending value with nulls or non-roles sorted first.
		 *
		 * @param compareTo The object to compare.
		 *
		 * @return The comparison value.
		 */
		public Integer compareTo(final Object compareTo) {
			if (compareTo == null || !(compareTo instanceof Role)) return -1;

			Role r = (Role)compareTo;
			if (this.value == r.value) return 0;
			if (this.value > r.value) return 1;
			return -1;
		}
	}

	/**
	 * Representation of DocuSign envelope recipient authentication methods.
	 */
	global class Authentication {
		/**
		 * Access code a recipient must enter before opening an envelope.
		 */
		@AuraEnabled
		global String accessCode { get; private set; }
		/**
		 * Whether the recipient's ID should be checked.
		 */
		@AuraEnabled
		global Boolean idCheckRequired { get; private set; }
		/**
		 * A list of phone numbers to which a SMS authentication code may be sent. Currently only one
		 * phone number is supported.
		 */
		@AuraEnabled
		global List<String> smsPhoneNumbers { get; private set; }

		/**
		 * Constructs recipient authentication.
		 *
		 * @param accessCode Access code a recipient must enter before opening an envelope.
		 * @param idCheckRequired Whether the recipient's ID should be checked.
		 * @param smsPhoneNumbers A list of phone numbers to which a SMS authentication code may be sent.
		 */
		global Authentication(
			final String accessCode,
			final Boolean idCheckRequired,
			final List<String> smsPhoneNumbers) {

			this.accessCode = accessCode;
			this.idCheckRequired = idCheckRequired;
			this.smsPhoneNumbers = smsPhoneNumbers;
		}

		/**
		 * Creates a deep copy of recipient authentication.
		 *
		 * @return A copy of the recipient authentication.
		 */
		public Authentication copy() {
			return new Authentication(
				this.accessCode,
				this.idCheckRequired,
				this.smsPhoneNumbers == null ? null : this.smsPhoneNumbers.clone());
		}
	}

	/**
	 * Represents localized DocuSign envelope recipient email settings.
	 */
	global class EmailSettings {
		/**
		 * The language code for the localized emails (e.g 'en', 'pt_BR').
		 */
		@AuraEnabled
		global String language { get; private set; }
		/**
		 * The localized language label.
		 */
		@AuraEnabled
		global String languageLabel { get; private set; }
		/**
		 * The localized email subject.
		 */
		@AuraEnabled
		global String subject { get; private set; }
		/**
		 * The localized email message.
		 */
		@AuraEnabled
		global String message { get; private set; }

		/**
		 * Constructs localized DocuSign envelope recipient email settings.
		 *
		 * @param language The language code for the localized emails.
		 * @param languageLabel The localized language label.
		 * @param subject The localized email subject.
		 * @param message The localized email message.
		 */
		global EmailSettings(final String language, final String languageLabel, final String subject,
			final String message) {

			this.language = language;
			this.languageLabel = languageLabel;
			this.subject = subject;
			this.message = message;
		}

		/**
		 * Creates a deep copy of the email settings.
		 *
		 * @return A copy of the email settings.
		 */
		public EmailSettings copy() {
			return new EmailSettings(
				this.language,
				this.languageLabel,
				this.subject,
				this.message);
		}

		/**
		 * Sets the <code>subject</code> property.
		 *
		 * @param subject The new email subject.
		 *
		 * @return The email settings with updated subject.
		 */
		public EmailSettings withSubject(final String subject) {
			this.subject = subject;
			return this;
		}

		/**
		 * Sets the <code>message</code> property.
		 *
		 * @param message The new email message.
		 *
		 * @return The email settings with updated message.
		 */
		public EmailSettings withMessage(final String message) {
			this.message = message;
			return this;
		}
	}

	/**
	 * DocuSign recipient status.
	 */
	global class Status implements Comparable {
		/**
		 * The ID of the underlying RecipientStatus__c record.
		 */
		@AuraEnabled
		global Id id { get; private set; }
		/**
		 * The Salesforce source entity.
		 */
		@AuraEnabled
		global Entity source { get; private set; }
		/**
		 * The recipient sequence.
		 */
		@AuraEnabled
		global Integer sequence { get; private set; }
		/**
		 * The DocuSign recipient type.
		 */
		@AuraEnabled
		global String type { get; private set; }
		/**
		 * The current status.
		 */
		@AuraEnabled
		global String status { get; private set; }
		/**
		 * The name of the recipient.
		 */
		@AuraEnabled
		global String name { get; private set; }
		/**
		 * The email address of the recipient.
		 */
		@AuraEnabled
		global String email { get; private set; }
		/**
		 * The routing order of the recipient.
		 */
		@AuraEnabled
		global Integer routingOrder { get; private set; }
		/**
		 * Date and time when the recipient received the envelope.
		 */
		@AuraEnabled
		global Datetime sent { get; private set; }
		/**
		 * Date and time when the recipient completed signing the envelope.
		 */
		@AuraEnabled
		global Datetime completed { get; private set; }
		/**
		 * The reason the recipient declined signing the envelope.
		 */
		@AuraEnabled
		global String reason { get; private set; }
		/**
		 * Date and time when the status was last updated.
		 */
		@AuraEnabled
		global Datetime lastStatusUpdate { get; private set; }
		/**
		 * Whether or not the recipient is in a final state.
		 */
		public Boolean isFinal {
			get {
				return this.status == STATUS_SIGNED
					|| this.status == STATUS_DECLINED
					|| this.status == STATUS_COMPLETED
					|| this.status == STATUS_CANCELED;
			}
		}

		/**
		 * Constructs a DocuSign recipient status.
		 *
		 *
		 * @param id The ID of the underlying RecipientStatus__c record.
		 * @param source The Salesforce source entity.
		 * @param sequence The recipient sequence.
		 * @param type The DocuSign recipient type.
		 * @param status The current status.
		 * @param name The name of the recipient.
		 * @param email The email address of the recipient.
		 * @param routingOrder The routing order of the recipient.
		 * @param sent Date and time when the recipient received the envelope.
		 * @param completed Date and time when the recipient completed signing the envelope.
		 * @param reason The reason the recipient declined signing the envelope.
		 * @param lastStatusUpdate Date and time when the status was last updated.
		 */
		global Status(
			final Id id,
			final Entity source,
			final String type,
			final Integer sequence,
			final String status,
			final String name,
			final String email,
			final Integer routingOrder,
			final Datetime sent,
			final Datetime completed,
			final String reason,
			final Datetime lastStatusUpdate) {

			this.id = id;
			this.source = source;
			this.sequence = sequence;
			this.type = type;
			this.status = status;
			this.name = name;
			this.email = email;
			this.routingOrder = routingOrder;
			this.sent = sent;
			this.completed = completed;
			this.reason = reason;
			this.lastStatusUpdate = lastStatusUpdate;
		}

		/**
		 * Cancels a recipient. This sets the status to <code>canceled</code> and <code>completed</code> and
		 * <code>lastStatusUpdate</code> to now. This is a final state for the recipient.
		 *
		 * @return The canceled recipient status.
		 */
		public Recipient.Status cancel() {
			this.status = STATUS_CANCELED;
			this.completed = Datetime.now();
			this.lastStatusUpdate = Datetime.now();
			return this;
		}

		/**
		 * Merges this recipient status with another. The <code>id</code> and <code>source</code> properties are
		 * copied from <code>other</code> if non-null.
		 *
		 * @param other The recipient status from which to merge data.
		 *
		 * @return The merged recipient status.
		 */
		public Recipient.Status mergeWith(final Recipient.Status other) {
			if (other != null) {
				this.id = other.id;
				this.source = other.source;
			}
			return this;
		}

		/**
		 * Used to sort recipient statuses by ascending routing order with nulls or non-roles sorted first.
		 *
		 * @param compareTo The object to compare.
		 *
		 * @return The comparison value.
		 */
		public Integer compareTo(final Object compareTo) {
			if (compareTo == null || !(compareTo instanceof Recipient.Status)) return -1;

			Recipient.Status that = (Recipient.Status)compareTo;
			if (this.routingOrder == that.routingOrder) return 0;
			if (this.routingOrder > that.routingOrder) return 1;
			return -1;
		}
	}

	/**
	 * Converts a recipient to recipient status.
	 *
	 * @param envelopeSent The date and time when the envelope was sent, or <code>null</code> if the envelope is a
	 * draft.
	 *
	 * @return The recipient status corresponding to the recipient.
	 */
	public Recipient.Status toRecipientStatus(final Datetime envelopeSent) {
		Boolean isSent = envelopeSent != null && this.routingOrder == 1;
		return new Recipient.Status(
			null,
			this.source,
			this.type,
			this.sequence,
			isSent ? STATUS_SENT : STATUS_CREATED,
			this.name,
			this.email,
			this.routingOrder,
			isSent ? envelopeSent : null,
			null,
			null,
			Datetime.now());
	}

	/**
	 * Used to sort recipients by ascending sequence with nulls or non-recipients sorted first.
	 *
	 * @param compareTo The object to compare.
	 *
	 * @return The comparison value.
	 */
	public Integer compareTo(final Object compareTo) {
		if (compareTo == null || !(compareTo instanceof Recipient)) return -1;

		Recipient r = (Recipient)compareTo;
		if (this.sequence == r.sequence) return 0;
		if (this.sequence > r.sequence) return 1;
		return -1;
	}

	/**
	 * Creates a deep copy of the DocuSign envelope recipient for resending. The <code>id</code> is nulled-out.
	 *
	 * @return A copy of the recipient.
	 */
	public Recipient copy() {
		return new Recipient(
			null,
			this.type,
			this.sequence,
			this.routingOrder,
			this.role,
			this.name,
			this.email,
			this.signingGroup == null ? null : this.signingGroup.copy(),
			this.phone,
			this.authentication == null ? null : this.authentication.copy(),
			this.note,
			this.emailSettings == null ? null : this.emailSettings.copy(),
			this.hostName,
			this.hostEmail,
			this.signNow,
			this.source == null ? null : this.source.copy(),
			this.readOnly,
			this.required);
	}

	/**
	 * Sets the recipient <code>type</code> and <code>signNow</code> properties.
	 *
	 * @param type The new recipient type.
	 * @param signNow Whether the recipient should sign now.
	 *
	 * @return The recipient with updated <code>type</code> and <code>signNow</code>.
	 */
	public Recipient withType(final String type, final Boolean signNow) {
		this.type = type;
		this.signNow = signNow;
		return this;
	}

	/**
	 * Sets the recipient <code>sequence</code> property.
	 *
	 * @param sequence The new recipient sequence.
	 *
	 * @return The recipient with updated <code>sequence</code>.
	 */
	public Recipient withSequence(final Integer sequence) {
		this.sequence = sequence;
		return this;
	}

	/**
	 * Sets the recipient <code>routingOrder</code> property.
	 *
	 * @param routingOrder The new recipient routing order.
	 *
	 * @return The recipient with updated <code>routingOrder</code>.
	 */
	public Recipient withRoutingOrder(final Integer routingOrder) {
		this.routingOrder = routingOrder;
		return this;
	}

	/**
	 * Sets the recipient <code>source</code> property.
	 *
	 * @param source The new recipient Salesforce source entity.
	 *
	 * @return The recipient with updated <code>source</code>.
	 */
	public Recipient withSource(final Entity source) {
		this.source = source;
		return this;
	}

	/**
	 * Sets the recipient <code>emailSettings</code> property.
	 *
	 * @param emailSettings The new recipient email settings.
	 *
	 * @return The recipient with updated <code>emailSettings</code>.
	 */
	global Recipient withEmailSettings(final EmailSettings emailSettings) {
		this.emailSettings = emailSettings;
		return this;
	}

	/**
	 * Sets the recipient <code>role</code> property.
	 *
	 * @param role The new recipient role.
	 *
	 * @return The recipient with updated <code>role</code>.
	 */
	global Recipient withRole(final Role role) {
		this.role = role;
		return this;
	}

	/**
	 * Sets the recipient <code>note</code> property.
	 *
	 * @param note The new recipient note.
	 *
	 * @return The recipient with updated <code>note</code>.
	 */
	global Recipient withNote(final String note) {
		this.note = note;
		return this;
	}

	/**
	 * Sets the recipient <code>authentication</code> property.
	 *
	 * @param authentication The new recipient authentication.
	 *
	 * @return The recipient with updated <code>authentication</code>.
	 */
	global Recipient withAuthentication(final Authentication authentication) {
		this.authentication = authentication;
		return this;
	}

	/**
	 * Sets the recipient <code>signNow</code> property.
	 *
	 * @param signNow Whether the recipient should sign now.
	 *
	 * @return The recipient with updated <code>signNow</code>.
	 */
	public Recipient withSignNow(final Boolean signNow) {
		this.signNow = signNow;
		return this;
	}

	/**
	 * Sets the recipient host name and email for in-person signing.
	 *
	 * @param hostName The name of the in-person signing host.
	 * @param hostEmail The email address of the in-person signing host.
	 * @param signNow Whether the recipient should sign the envelope immediately.
	 *
	 * @return The recipient with updated <code>hostName</code> and <code>hostEmail</code>.
	 */
	public Recipient withHost(final String hostName, final String hostEmail, final Boolean signNow) {
		this.hostName = hostName;
		this.hostEmail = hostEmail;
		this.signNow = signNow;
		return this;
	}

	/**
	 * Recipient search behaviors:
	 * <ul>
	 *     <li><code>CompoundMatchBeginning</code>: Match beginning of compound name field: <code>SELECT X FROM Y WHERE Name LIKE 'name%'</code>.</li>
	 *     <li><code>CompoundMatchExact</code>: Match exact compound name field: <code>SELECT X FROM Y WHERE Name = 'name'</code>.</li>
	 *     <li><code>CompoundMatchAny</code>: Match any part of compound name field: <code>SELECT X FROM Y WHERE Name LIKE '%name%'</code>. Not recommended as this creates extremely inefficient queries that may time out and will break if the fields are encrypted.</li>
	 *     <li><code>DiscreteMatchBeginning</code>: Match beginning of discrete name fields: <code>SELECT X FROM Y WHERE FirstName LIKE 'firstName%' AND LastName LIKE 'lastName%'</code>.</li>
	 *     <li><code>DiscreteMatchExact</code>: Match exact discrete name fields: <code>SELECT X FROM Y WHERE FirstName = 'firstName' AND LastName = 'lastName'</code>.</li>
	 *     <li><code>DiscreteMatchAny</code>: Match any part of discrete name fields: <code>SELECT X FROM Y WHERE WHERE FirstName LIKE '%firstName%' AND LastName LIKE '%lastName%'</code>. Not recommended as this creates extremely inefficient queries that may time out and will break if the fields are encrypted.</li>
	 * </ul>
 	 */
	public enum SearchBehavior {
		CompoundMatchBeginning,
		CompoundMatchExact,
		CompoundMatchAny,
		DiscreteMatchBeginning,
		DiscreteMatchExact,
		DiscreteMatchAny
	}

	/**
	 * Recipient resend result.
	 */
	global class ResendResult {
		/**
		 * The recipient sequence.
		 */
		@AuraEnabled
		global Integer sequence { get; private set; }
		/**
		 * The recipient email address.
		 */
		@AuraEnabled
		global String email { get; private set; }
		/**
		 * The recipient routing order.
		 */
		@AuraEnabled
		global Integer routingOrder { get; private set; }
		/**
		 * The error encountered during update, if any.
		 */
		@AuraEnabled
		global APIError error { get; private set; }

		/**
		 * Constructs a recipient resend result.
		 *
		 * @param sequence The recipient sequence.
		 * @param email The recipient email address.
		 * @param routingOrder The recipient routing order.
		 * @param error The error encountered during update, if any.
		 */
		public ResendResult(final Integer sequence, final String email, final Integer routingOrder, final APIError error) {
			this.sequence = sequence;
			this.email = email;
			this.routingOrder = routingOrder;
			this.error = error;
		}
	}
}