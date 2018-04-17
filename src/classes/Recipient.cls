public class Recipient implements Comparable {

	public static final String TYPE_SIGNER = 'Signer';
	public static final String TYPE_IN_PERSON_SIGNER = 'InPersonSigner';
	public static final String TYPE_CARBON_COPY = 'CarbonCopy';
	public static final String TYPE_CERTIFIED_DELIVERY = 'CertifiedDelivery';
	public static final String TYPE_AGENT = 'Agent';
	public static final String TYPE_EDITOR = 'Editor';
	public static final String TYPE_INTERMEDIARY = 'Intermediary';

	public static final String SOURCE_USER = 'User';
	public static final String SOURCE_CONTACT = 'Contact';
	public static final String SOURCE_LEAD = 'Lead';
	public static final String SOURCE_CUSTOM = 'Custom';

	public Id id { get; private set; }
	public String type { get; private set; }
	public Integer sequence { get; private set; }
	public Integer routingOrder { get; private set; }
	public Role role { get; private set; }
	public String name { get; private set; }
	public String email { get; private set; }
	public SigningGroup signingGroup { get; private set; }
	public String phone { get; private set; }
	public Authentication authentication { get; private set; }
	public String note { get; private set; }
	public EmailSettings emailSettings { get; private set; }
	public String hostName { get; private set; }
	public String hostEmail { get; private set; }
	public Boolean signNow { get; private set; }
	public Entity source { get; private set; }
	public Boolean isContact {
		get {
			return source != null && source.type == SOURCE_CONTACT;
		}
	}
	public Boolean isLead {
		get {
			return source != null && source.type == SOURCE_LEAD;
		}
	}
	public Boolean isUser {
		get {
			return source != null && source.type == SOURCE_USER;
		}
	}
	public Boolean isCustom {
		get {
			return source != null && source.type == SOURCE_CUSTOM;
		}
	}
	public Boolean isSigningGroup {
		get {
			return this.signingGroup != null;
		}
	}

	public Recipient(
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
		final Entity source) {

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
	}

	public static Recipient newSigningGroup(
		final Integer routingOrder,
		final String type,
		final Role role,
		final SigningGroup signingGroup,
		final Authentication authentication,
		final String note) {

		return new Recipient(
			null,
			type,
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
			null);
	}

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
			null);
	}

	public static Recipient fromSource(final String name, final String email, final String phone, final String role,
		final Entity source) {

		return new Recipient(
			null,
			TYPE_SIGNER,
			null,
			null,
			String.isBlank(role) ? null : new Role(role, null),
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
			source);
	}

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
			null);
	}

	public class SigningGroup {

		public Integer id { get; private set; }
		public String name { get; private set; }

		public SigningGroup(final Integer id, final String name) {
			this.id = id;
			this.name = name;
		}
	}

	public class Role implements Comparable {
		public String name { get; private set; }
		public Integer value { get; private set; }

		public Role(final String name, final Integer value) {
			this.name = name;
			this.value = value;
		}

		public Integer compareTo(final Object compareTo) {
			if (compareTo == null || !(compareTo instanceof Role)) return -1;

			Role r = (Role)compareTo;
			if (this.value == r.value) return 0;
			if (this.value > r.value) return 1;
			return -1;
		}
	}

	public class Authentication {
		public String accessCode { get; private set; }
		public Boolean idCheckRequired { get; private set; }
		public List<String> smsPhoneNumbers { get; private set; }

		public Authentication(
			final String accessCode,
			final Boolean idCheckRequired,
			final List<String> smsPhoneNumbers) {

			this.accessCode = accessCode;
			this.idCheckRequired = idCheckRequired;
			this.smsPhoneNumbers = smsPhoneNumbers;
		}
	}

	public class EmailSettings {
		public String language { get; private set; }
		public String languageLabel { get; private set; }
		public String subject { get; private set; }
		public String message { get; private set; }

		public EmailSettings(final String language, final String languageLabel, final String subject,
			final String message) {

			this.language = language;
			this.languageLabel = languageLabel;
			this.subject = subject;
			this.message = message;
		}

		public EmailSettings withSubject(final String subject) {
			this.subject = subject;
			return this;
		}

		public EmailSettings withMessage(final String message) {
			this.message = message;
			return this;
		}
	}

	public Integer compareTo(final Object compareTo) {
		if (compareTo == null || !(compareTo instanceof Recipient)) return -1;

		Recipient r = (Recipient)compareTo;
		if (this.sequence == r.sequence) return 0;
		if (this.sequence > r.sequence) return 1;
		return -1;
	}

	public Recipient withSequence(final Integer sequence) {
		this.sequence = sequence;
		return this;
	}

	public Recipient withRoutingOrder(final Integer routingOrder) {
		this.routingOrder = routingOrder;
		return this;
	}

	public Recipient withSource(final Entity source) {
		this.source = source;
		return this;
	}

	public Recipient withEmailSettings(final Recipient.EmailSettings emailSettings) {
		this.emailSettings = emailSettings;
		return this;
	}
}
