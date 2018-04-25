public class Envelope {

	public Id id { get; private set; }
	public String name { get; private set; }
	public UUID docuSignId { get; private set; }
	public Id envelopeConfigurationId { get; private set; }
	public List<Document> documents { get; private set; }
	public List<Recipient> recipients { get; private set; }
	public List<CustomField> customFields { get; private set; }
	public Notifications notifications { get; private set; }
	public String emailSubject { get; private set; }
	public String emailMessage { get; private set; }
	public Entity source { get; private set; }
	public Datetime sent { get; private set; }
	public Boolean isSent {
		get {
			return this.sent != null && this.sent <= Datetime.now();
		}
	}
	public Boolean hasDocuments {
		get {
			return Collection.isNotEmpty(this.documents);
		}
	}
	public Boolean hasTemplates {
		get {
			if (this.documents != null) {
				for (Document d : this.documents) {
					if (d.templateId != null) {
						return true;
					}
				}
			}
			return false;
		}
	}
	public Boolean hasRecipients {
		get {
			return Collection.isNotEmpty(this.recipients);
		}
	}

	public Envelope(
		final Id id,
		final String name,
		final UUID docuSignId,
		final Id envelopeConfigurationId,
		final List<Document> documents,
		final List<Recipient> recipients,
		final List<CustomField> customFields,
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final Entity source,
		final Datetime sent) {

		this.id = id;
		this.name = name;
		this.docuSignId = docuSignId;
		this.envelopeConfigurationId = envelopeConfigurationId;
		this.documents = documents;
		this.recipients = recipients;
		this.customFields = customFields;
		this.notifications = notifications;
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		this.source = source;
		this.sent = sent;
	}

	public Envelope(
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final Entity source) {

		this(null, null, null, null, null, null, null, notifications, emailSubject, emailMessage, source, null);
	}

	public class Notifications {

		public Boolean remind { get; private set; }
		public Integer remindAfterDays { get; private set; }
		public Integer remindFrequencyDays { get; private set; }
		public Boolean expires { get; private set; }
		public Integer expireAfterDays { get; private set; }
		public Integer expireWarnDays { get; private set; }
		public Boolean updateChatter { get; private set; }

		public Notifications(final Boolean remind, final Integer remindAfterDays, final Integer remindFrequencyDays,
			final Boolean expires, final Integer expireAfterDays, final Integer expireWarnDays,
			final Boolean updateChatter) {

			this.remind = remind;
			this.remindAfterDays = remindAfterDays;
			this.remindFrequencyDays = remindFrequencyDays;
			this.expires = expires;
			this.expireAfterDays = expireAfterDays;
			this.expireWarnDays = expireWarnDays;
			this.updateChatter = updateChatter;
		}

		public Notifications copy() {
			return new Notifications(
				this.remind,
				this.remindAfterDays,
				this.remindFrequencyDays,
				this.expires,
				this.expireAfterDays,
				this.expireWarnDays,
				this.updateChatter);
		}
	}

	public class Options {

		public Boolean sendNow { get; private set; }
		public Boolean includeDefaultAnchorTabs { get; private set; }
		public Boolean fetchDocuments { get; private set; }
		public Boolean useAccountNotificationDefaults { get; private set; }

		public Options(
			final Boolean sendNow,
			final Boolean includeDefaultAnchorTabs,
			final Boolean fetchDocuments,
			final Boolean useAccountNotificationDefaults) {

			this.sendNow = sendNow;
			this.includeDefaultAnchorTabs = includeDefaultAnchorTabs;
			this.fetchDocuments = fetchDocuments;
			this.useAccountNotificationDefaults = useAccountNotificationDefaults;
		}
	}

	public Envelope copy() {
		List<Document> copiedDocuments = null;
		if (this.documents != null) {
			copiedDocuments = new List<Document>();
			for (Document d : this.documents) {
				copiedDocuments.add(d.copy());
			}
		}
		List<Recipient> copiedRecipients = null;
		if (this.recipients != null) {
			copiedRecipients = new List<Recipient>();
			for (Recipient r : this.recipients) {
				copiedRecipients.add(r.copy());
			}
		}
		List<CustomField> copiedCustomFields = null;
		if (this.customFields != null) {
			copiedCustomFields = new List<CustomField>();
			for (CustomField cf : this.customFields) {
				copiedCustomFields.add(cf.copy());
			}
		}

		return new Envelope(
			null,
			this.name,
			null,
			this.envelopeConfigurationId,
			copiedDocuments,
			copiedRecipients,
			copiedCustomFields,
			this.notifications == null ? null : this.notifications.copy(),
			this.emailSubject,
			this.emailMessage,
			this.source == null ? null : this.source.copy(),
			null);
	}

	public Envelope withId(final Id id) {
		this.id = id;
		return this;
	}

	public Envelope withDocuSignId(final UUID docuSignId) {
		this.docuSignId = docuSignId;
		return this;
	}

	public Envelope withEnvelopeConfigurationId(final Id envelopeConfigurationId) {
		this.envelopeConfigurationId = envelopeConfigurationId;
		return this;
	}

	public Envelope addDocuments(final List<Document> documents) {
		if (this.documents == null) this.documents = new List<Document>();
		if (Collection.isNotEmpty(documents)) this.documents.addAll(documents);
		return this;
	}

	public Envelope withDocuments(final List<Document> documents) {
		this.documents = documents;
		return this;
	}

	public Envelope addRecipients(final List<Recipient> recipients) {
		if (this.recipients == null) this.recipients = new List<Recipient>();
		if (Collection.isNotEmpty(recipients)) this.recipients.addAll(recipients);
		return this;
	}

	public Envelope withRecipients(final List<Recipient> recipients) {
		this.recipients = recipients;
		return this;
	}

	public Envelope withCustomFields(final List<CustomField> customFields) {
		this.customFields = customFields;
		return this;
	}

	public Envelope withNotifications(final Notifications notifications) {
		this.notifications = notifications;
		return this;
	}

	public Envelope withEmail(final String emailSubject, final String emailMessage) {
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		return this;
	}

	public Envelope withSent(final Datetime sent) {
		this.sent = sent;
		return this;
	}
}
