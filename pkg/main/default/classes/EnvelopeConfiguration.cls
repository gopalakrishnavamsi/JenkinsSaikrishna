/**
 * A DocuSign eSignature envelope configuration.
 */
global class EnvelopeConfiguration extends Envelope {

	public static final String DOCUMENT_TYPE_TEMPLATE_DOCUMENT = 'TemplateDocument';
	public static final String DOCUMENT_TYPE_SOURCE_FILES = 'SourceFiles';

	@AuraEnabled
	public String sourceObject { get; private set; }
	@AuraEnabled
	public List<Tab> mergeFields { get; private set; }
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

		super(
			id,
			name,
			docuSignId,
			id,
			documents,
			recipients,
			customFields,
			notifications,
			emailSubject,
			emailMessage,
			senderPermissions,
			options,
			null,
			null);

		this.sourceObject = sourceObject;
		this.mergeFields = mergeFields == null ? new List<Tab>() : mergeFields;
		this.isDraft = isDraft;
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
}
