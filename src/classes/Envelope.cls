/**
 * Representation of a DocuSign envelope.
 */
public class Envelope {
	/**
	 * The ID of the associated Envelope__c record.
	 */
	public Id id { get; private set; }
	/**
	 * The name of the envelope.
	 */
	public String name { get; private set; }
	/**
	 * The DocuSign ID of the envelope, assigned when the envelope is sent or a draft envelope is created.
	 */
	public UUID docuSignId { get; private set; }
	/**
	 * The ID of the configuration (f.k.a custom button) used to create the envelope.
	 */
	public Id envelopeConfigurationId { get; private set; }
	/**
	 * A list of documents contained by the envelope.
	 */
	public List<Document> documents { get; private set; }
	/**
	 * A list of recipients who receive the envelope.
	 */
	public List<Recipient> recipients { get; private set; }
	/**
	 * A list of envelope custom fields. These are not persisted via the Envelope__c object.
	 */
	public List<CustomField> customFields { get; private set; }
	/**
	 * The reminder and expiration settings for the envelope.
	 */
	public Notifications notifications { get; private set; }
	/**
	 * The subject of the email recipients receive.
	 */
	public String emailSubject { get; private set; }
	/**
	 * The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 */
	public String emailMessage { get; private set; }
	/**
	 * The Salesforce source object for the envelope (e.g. Opportunity or Lead).
	 */
	public Entity source { get; private set; }
	/**
	 * The date and time when the envelope was sent.
	 */
	public Datetime sent { get; private set; }
	/**
	 * Read-only property indicating whether the envelope is sent.
	 */
	public Boolean isSent {
		get {
			return this.sent != null && this.sent <= Datetime.now();
		}
	}
	/**
	 * Read-only property indicating whether the envelope contains documents.
	 */
	public Boolean hasDocuments {
		get {
			return Collection.isNotEmpty(this.documents);
		}
	}
	/**
	 * Read-only property indicating whether the envelope contains DocuSign templates.
	 */
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
	/**
	 * Read-only property indicating whether the envelope contains recipients.
	 */
	public Boolean hasRecipients {
		get {
			return Collection.isNotEmpty(this.recipients);
		}
	}

	/**
	 * Constructs a DocuSign envelope.
	 *
	 * @param id The ID of the associated Envelope__c record.
	 * @param name The name of the envelope.
	 * @param docuSignId The DocuSign ID of the envelope.
	 * @param envelopeConfigurationId The ID of the configuration (f.k.a custom button) used to create the envelope.
	 * @param documents A list of documents contained by the envelope.
	 * @param recipients A list of recipients who receive the envelope.
	 * @param customFields A list of envelope custom fields.
	 * @param notifications The reminder and expiration settings for the envelope.
	 * @param emailSubject The subject of the email recipients receive.
	 * @param emailMessage The message of the email recipients receive.
	 * @param source The Salesforce source object for the envelope.
	 * @param sent The date and time when the envelope was sent.
	 */
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

	/**
	 * Constructs an empty envelope.
	 *
	 * @param notifications The reminder and expiration settings for the envelope.
	 * @param emailSubject The subject of the email recipients receive.
	 * @param emailMessage The message of the email recipients receive.
	 * @param source The Salesforce source object for the envelope.
	 */
	public Envelope(
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final Entity source) {

		this(null, null, null, null, null, null, null, notifications, emailSubject, emailMessage, source, null);
	}

	/**
	 * A DocuSign envelope's reminder and expiration settings.
	 */
	public class Notifications {
		/**
		 * Whether or not to remind recipients to sign.
		 */
		public Boolean remind { get; private set; }
		/**
		 * How many days to wait before sending a reminder.
		 */
		public Integer remindAfterDays { get; private set; }
		/**
		 * How many days between sending reminders.
		 */
		public Integer remindFrequencyDays { get; private set; }
		/**
		 * Whether or not the envelope automatically expires (is voided).
		 */
		public Boolean expires { get; private set; }
		/**
		 * How many days before the envelope expires.
		 */
		public Integer expireAfterDays { get; private set; }
		/**
		 * How many days prior to expiration to send a warning to recipients.
		 */
		public Integer expireWarnDays { get; private set; }
		/**
		 * Whether or not to update Chatter with envelope and recipient events.
		 */
		public Boolean updateChatter { get; private set; }

		/**
		 * Constructs an envelope notification settings.
		 *
		 * @param remind Whether or not to remind recipients to sign.
		 * @param remindAfterDays How many days to wait before sending a reminder.
		 * @param remindFrequencyDays How many days between sending reminders.
		 * @param expires Whether or not the envelope automatically expires (is voided).
		 * @param expireAfterDays How many days before the envelope expires.
		 * @param expireWarnDays How many days prior to expiration to send a warning to recipients.
		 * @param updateChatter Whether or not to update Chatter with envelope and recipient events.
		 */
		public Notifications(
			final Boolean remind,
			final Integer remindAfterDays,
			final Integer remindFrequencyDays,
			final Boolean expires,
			final Integer expireAfterDays,
			final Integer expireWarnDays,
			final Boolean updateChatter) {

			this.remind = remind;
			this.remindAfterDays = remindAfterDays;
			this.remindFrequencyDays = remindFrequencyDays;
			this.expires = expires;
			this.expireAfterDays = expireAfterDays;
			this.expireWarnDays = expireWarnDays;
			this.updateChatter = updateChatter;
		}

		/**
		 * Creates a deep copy of the envelope notifications.
		 *
		 * @return A copy of the envelope notifications.
		 */
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

	/**
	 * Representation of DocuSign envelope options.
	 */
	public class Options {
		/**
		 * Whether to send the envelope now or create a draft.
		 */
		public Boolean sendNow { get; private set; }
		/**
		 * Whether to include default anchor tabs that map to recipient roles.
		 */
		public Boolean includeDefaultAnchorTabs { get; private set; }
		/**
		 * Whether to push encoded documents to DocuSign or have DocuSign pull the documents from Salesforce.
		 */
		public Boolean fetchDocuments { get; private set; }
		/**
		 * Whether to use the configured DocuSign account notification defaults.
		 */
		public Boolean useAccountNotificationDefaults { get; private set; }

		/**
		 * Constructs DocuSign envelope options.
		 *
		 * @param sendNow Whether to send the envelope now or create a draft.
		 * @param includeDefaultAnchorTabs Whether to include default anchor tabs that map to recipient roles.
		 * @param fetchDocuments Whether to push encoded documents to DocuSign or have DocuSign pull the documents from Salesforce.
		 * @param useAccountNotificationDefaults Whether to use the configured DocuSign account notification defaults.
		 */
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

	/**
	 * Creates a deep copy of the envelope without its <code>id`, <code>docuSignId`, and <code>sent</code> properties.
	 *
	 * @return A copy of the envelope.
	 */
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

	/**
	 * Sets the envelope's <code>id</code> property.
	 *
	 * @param id The new ID of the associated Envelope__c record.
	 *
	 * @return This envelope with the updated <code>id</code> property.
	 */
	public Envelope withId(final Id id) {
		this.id = id;
		return this;
	}

	/**
	 * Sets the envelope's <code>docuSignId</code> property.
	 *
	 * @param docuSignId The new DocuSign ID of the envelope.
	 *
	 * @return This envelope with the updated <code>docuSignId</code> property.
	 */
	public Envelope withDocuSignId(final UUID docuSignId) {
		this.docuSignId = docuSignId;
		return this;
	}

	/**
	 * Sets the envelope's <code>envelopeConfigurationId</code> property.
	 *
	 * @param envelopeConfigurationId The new envelope configuration ID.
	 *
	 * @return This envelope with the updated <code>envelopeConfigurationId</code> property.
	 */
	public Envelope withEnvelopeConfigurationId(final Id envelopeConfigurationId) {
		this.envelopeConfigurationId = envelopeConfigurationId;
		return this;
	}

	/**
	 * Adds one or more documents to the envelope.
	 *
	 * @param documents The list of documents to add.
	 *
	 * @return This envelope with the added documents.
	 */
	public Envelope addDocuments(final List<Document> documents) {
		if (this.documents == null) this.documents = new List<Document>();
		if (Collection.isNotEmpty(documents)) this.documents.addAll(documents);
		return this;
	}

	/**
	 * Sets the envelope's <code>documents</code> property.
	 *
	 * @param documents The new list of documents.
	 *
	 * @return This envelope with the updated <code>documents</code> property.
	 */
	public Envelope withDocuments(final List<Document> documents) {
		this.documents = documents;
		return this;
	}

	/**
	 * Adds one or more recipients to the envelope.
	 *
	 * @param recipients The list of recipients to add.
	 *
	 * @return This envelope with the added recipients.
	 */
	public Envelope addRecipients(final List<Recipient> recipients) {
		if (this.recipients == null) this.recipients = new List<Recipient>();
		if (Collection.isNotEmpty(recipients)) this.recipients.addAll(recipients);
		return this;
	}

	/**
	 * @descriptions Sets the envelope's <code>recipients</code> property.
	 *
	 * @param recipients The new list of recipients.
	 *
	 * @return This envelope with the updated <code>recipients</code> property.
	 */
	public Envelope withRecipients(final List<Recipient> recipients) {
		this.recipients = recipients;
		return this;
	}

	/**
	 * @descriptions Sets the envelope's <code>customFields</code> property.
	 *
	 * @param customFields The new list of custom fields.
	 *
	 * @return This envelope with the updated <code>customFields</code> property.
	 */
	public Envelope withCustomFields(final List<CustomField> customFields) {
		this.customFields = customFields;
		return this;
	}

	/**
	 * @descriptions Sets the envelope's <code>notifications</code> property.
	 *
	 * @param notifications The new notification settings.
	 *
	 * @return This envelope with the updated <code>notifications</code> property.
	 */
	public Envelope withNotifications(final Notifications notifications) {
		this.notifications = notifications;
		return this;
	}

	/**
	 * Sets the envelope's <code>emailSubject</code> and <code>emailMessage</code> properties.
	 *
	 * @param emailSubject The new email subject.
	 * @param emailMessage The new email message.
	 *
	 * @return This envelope with the updated <code>emailSubject</code> and <code>emailMessage</code> properties.
	 */
	public Envelope withEmail(final String emailSubject, final String emailMessage) {
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		return this;
	}

	/**
	 * Sets the envelope's <code>sent</code> property.
	 *
	 * @param sent The new date and time when the envelope was sent.
	 *
	 * @return This envelope with the updated <code>sent</code> property.
	 */
	public Envelope withSent(final Datetime sent) {
		this.sent = sent;
		return this;
	}
}
