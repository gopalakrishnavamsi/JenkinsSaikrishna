/**
 * A DocuSign eSignature envelope configuration.
 */
global class EnvelopeConfiguration {

	public static final String DOCUMENT_TYPE_TEMPLATE_DOCUMENT = 'TemplateDocument';
	public static final String DOCUMENT_TYPE_SOURCE_FILES = 'SourceFiles';

	/**
	 * The ID of the associated dfsle__EnvelopeConfiguration__c record.
	 */
	@AuraEnabled
	public Id id { get; private set; }
	/**
	 * The name of the envelope configuration.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The Salesforce object type name.
	 */
	@AuraEnabled
	public String sourceObject { get; private set; }
	/**
	 * The DocuSign ID of the associated template.
	 */
	@AuraEnabled
	public UUID docuSignId { get; private set; }
	/**
	 * A list of documents contained by the envelope.
	 */
	@AuraEnabled
	public List<Document> documents { get; private set; }
	/**
	 * A list of recipients who will receive the envelope.
	 */
	@AuraEnabled
	public List<Recipient> recipients { get; private set; }
	/**
	 * A list of envelope custom fields.
	 */
	@AuraEnabled
	public List<CustomField> customFields { get; private set; }
	/**
	 * The reminder and expiration settings for the envelope.
	 */
	@AuraEnabled
	public Notifications notifications { get; private set; }
	/**
	 * The subject of the email recipients receive.
	 */
	@AuraEnabled
	public String emailSubject { get; private set; }
	/**
	 * The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 */
	@AuraEnabled
	public String emailMessage { get; private set; }
	/**
	 * Salesforce merge fields available to the envelope configuration.
	 */
	@AuraEnabled
	public List<Tab> mergeFields { get; private set; }
	/**
	 * Envelope sender permissions.
	 */
	@AuraEnabled
	public Envelope.Permissions senderPermissions { get; private set; }
	/**
	 * The envelope options.
	 */
	@AuraEnabled
	public Envelope.Options options { get; private set; }
	/**
	 * Whether or the envelope configuration is in draft mode.
	 */
	@AuraEnabled
	public Boolean isDraft { get; private set; }

	public EnvelopeConfiguration(
		final Id id,
		final String name,
		final String sourceObject,
		final UUID docuSignId,
		final List<Document> documents,
		final List<Recipient> recipients,
		final List<CustomField> customFields,
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final List<Tab> mergeFields,
		final Envelope.Permissions senderPermissions,
		final Envelope.Options options,
		final Boolean isDraft) {

		this.id = id;
		this.name = name;
		this.sourceObject = sourceObject;
		this.docuSignId = docuSignId;
		this.documents = documents == null ? new List<Document>() : documents;
		this.recipients = recipients == null ? new List<Recipient>() : recipients;
		this.customFields = customFields == null ? new List<CustomField>() : customFields;
		this.notifications = notifications;
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		this.mergeFields = mergeFields == null ? new List<Tab>() : mergeFields;
		this.senderPermissions = senderPermissions == null ? Envelope.DEFAULT_PERMISSIONS : senderPermissions;
		this.options = options == null ? Envelope.DEFAULT_OPTIONS : options;
		this.isDraft = isDraft;
	}

	/**
	 * Sets the envelope configuration's <code>id</code> property.
	 *
	 * @param id The new ID of the associated dfsle__EnvelopeConfiguration__c record.
	 *
	 * @return The envelope configuration with an updated <code>id</code> property.
	 */
	public EnvelopeConfiguration withId(final Id id) {
		this.id = id;
		return this;
	}

	/**
	 * Sets the envelope configuration's <code>docuSignId</code> property.
	 *
	 * @param docuSignId The new DocuSign ID of the associated template.
	 *
	 * @return The envelope configuration with an updated <code>docuSignId</code> property.
	 */
	public EnvelopeConfiguration withDocuSignId(final UUID docuSignId) {
		this.docuSignId = docuSignId;
		return this;
	}

	/**
	 * Sets the envelope configuration's <code>documents</code> property.
	 *
	 * @param documents The new list of documents.
	 *
	 * @return The envelope configuration with an updated <code>documents</code> property.
	 */
	public EnvelopeConfiguration withDocuments(final List<Document> documents) {
		this.documents = new List<Document>();
		if (documents != null) {
			Integer sequence = 1;
			for (Document d : documents) {
				this.documents.add(d.withSequence(sequence++));
			}
		}
		return this;
	}

	/**
	 * @descriptions Sets the envelope configuration's <code>recipients</code> property.
	 *
	 * @param recipients The new list of recipients.
	 *
	 * @return The envelope configuration with an updated <code>recipients</code> property.
	 */
	public EnvelopeConfiguration withRecipients(final List<Recipient> recipients) {
		this.recipients = new List<Recipient>();
		if (recipients != null) {
			Integer sequence = 1;
			for (Recipient r : recipients) {
				if (r.routingOrder == null) r = r.withRoutingOrder(sequence);
				this.recipients.add(r.withSequence(sequence++));
			}
		}
		return this;
	}

	// 1 file linked to the DEC
	public class TemplateDocument extends Document {

		public TemplateDocument(
			final Id id,
			final Id contentDocumentId,
			final Integer sequence,
			final String name,
			final String extension,
			final Boolean readOnly,
			final Boolean required) {

			super(
				id,
				DOCUMENT_TYPE_TEMPLATE_DOCUMENT,
				sequence,
				name,
				extension,
				contentDocumentId,
				readOnly,
				required);
		}
	}

	// 0 - N files linked to source
	public class SourceFiles extends Document {

		@AuraEnabled
		public Query.Filter filter { get; private set; }

		public SourceFiles(
			final Id id,
			final Query.Filter filter,
			final Integer sequence,
			final Boolean readOnly,
			final Boolean required) {

			super(
				id,
				DOCUMENT_TYPE_SOURCE_FILES,
				sequence,
				null,
				null,
				null,
				readOnly,
				required);

			this.filter = filter;
		}
	}

	// 0 - 1 recipient
	public class LookupRecipient extends Recipient {

		@AuraEnabled
		public Query.Relationship relationship { get; private set; }

		public LookupRecipient(
			final Id id,
			final Query.Relationship relationship,
			final String type,
			final Integer sequence,
			final Integer routingOrder,
			final String role,
			final String name,
			final String email,
			final SigningGroup signingGroup,
			final String phone,
			final Recipient.Authentication authentication,
			final String note,
			final Recipient.EmailSettings emailSettings,
			final String hostName,
			final String hostEmail,
			final Boolean signNow,
			final Entity source,
			final Boolean readOnly,
			final Boolean required) {

			super(
				id,
				type,
				sequence,
				routingOrder,
				String.isBlank(role) ? null : new Recipient.Role(role),
				name,
				email,
				signingGroup,
				phone,
				authentication,
				note,
				emailSettings,
				hostName,
				hostEmail,
				signNow,
				source,
				readOnly,
				required);

			this.relationship = relationship;
		}

		public LookupRecipient(
			final Query.Relationship relationship,
			final String type,
			final Integer routingOrder,
			final String role,
			final Boolean readOnly,
			final Boolean required) {

			this(
				null,
				relationship,
				type,
				null,
				routingOrder,
				role,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				false,
				null,
				readOnly,
				required);
		}
	}

	// 0 - N recipients
	public class RelatedRecipients extends Recipient {

		@AuraEnabled
		public Query.Relationship relationship { get; private set; }
		@AuraEnabled
		public Query.Filter filter { get; private set; }
		@AuraEnabled
		public Boolean incrementRoutingOrder { get; private set; }
		@AuraEnabled
		public List<String> roles { get; private set; }

		public RelatedRecipients(
			final Id id,
			final Query.Relationship relationship,
			final Query.Filter filter,
			final Boolean incrementRoutingOrder,
			final String type,
			final Integer sequence,
			final Integer startingRoutingOrder,
			final List<String> roles,
			final String name,
			final String email,
			final SigningGroup signingGroup,
			final String phone,
			final Recipient.Authentication authentication,
			final String note,
			final Recipient.EmailSettings emailSettings,
			final String hostName,
			final String hostEmail,
			final Boolean signNow,
			final Entity source,
			final Boolean readOnly,
			final Boolean required) {

			super(
				id,
				type,
				sequence,
				startingRoutingOrder,
				Collection.isEmpty(roles) ? null : new Recipient.Role((String)Collection.head(roles)),
				name,
				email,
				signingGroup,
				phone,
				authentication,
				note,
				emailSettings,
				hostName,
				hostEmail,
				signNow,
				source,
				readOnly,
				required);

			this.relationship = relationship;
			this.filter = filter;
			this.incrementRoutingOrder = incrementRoutingOrder;
			this.roles = roles == null ? new List<String>() : roles;
		}

		public RelatedRecipients(
			final Query.Relationship relationship,
			final Query.Filter filter,
			final String type,
			final Integer startingRoutingOrder,
			final Boolean incrementRoutingOrder,
			final List<String> roles,
			final Boolean readOnly,
			final Boolean required) {

			this(
				null,
				relationship,
				filter,
				incrementRoutingOrder,
				type,
				null,
				startingRoutingOrder,
				roles,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				false,
				null,
				readOnly,
				required);
		}
	}

	public EnvelopeConfiguration withMergeFields(final List<Tab> mergeFields) {
		this.mergeFields = mergeFields == null ? new List<Tab>() : mergeFields;
		return this;
	}

	public class Listing {
		@AuraEnabled
		public Id id { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String sourceObject { get; private set; }
		@AuraEnabled
		public Datetime lastModifiedDate { get; private set; }

		public Listing(
			final Id id,
			final String name,
			final String sourceObject,
			final Datetime lastModifiedDate) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.lastModifiedDate = lastModifiedDate;
		}
	}

}
