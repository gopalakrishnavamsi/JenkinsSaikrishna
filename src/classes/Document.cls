/**
 * Representation of a DocuSign envelope document.
 */
public class Document {
	/**
	 * DocuSign template document type constant.
	 */
	public static final String TYPE_TEMPLATE = 'Template';
	/**
	 * Salesforce file/content version document type constant.
	 */
	public static final String TYPE_FILE = 'ContentVersion';
	/**
	 * Salesforce document type constant.
	 */
	public static final String TYPE_DOCUMENT = 'Document';

	/**
	 * The ID of the associated Document__c record.
	 */
	@AuraEnabled
	public Id id { get; private set; }
	/**
	 * The type of the document.
	 */
	@AuraEnabled
	public String type { get; private set; }
	/**
	 * The ordinal sequence of the document as it appears in an envelope.
	 */
	@AuraEnabled
	public Integer sequence { get; private set; }
	/**
	 * The name of the document.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The size of the document in bytes.
	 */
	@AuraEnabled
	public Integer size { get; private set; }
	/**
	 * The file extension of the document.
	 */
	@AuraEnabled
	public String extension { get; private set; }
	/**
	 * Date and time when the document was created.
	 */
	@AuraEnabled
	public Datetime created { get; private set; }
	/**
	 * The Salesforce source record ID or the DocuSign template ID.
	 */
	@AuraEnabled
	public String sourceId { get; private set; }
	/**
	 * Read-only property representing the DocuSign template ID if any.
	 */
	@AuraEnabled
	public UUID templateId {
		get {
			if (String.isNotBlank(this.sourceId) && this.type == TYPE_TEMPLATE) {
				return UUID.tryParse(this.sourceId);
			}
			return null;
		}
	}

	/**
	 * Constructs a new DocuSign envelope document.
	 *
	 * @param id The ID of the associated Document__c record.
	 * @param type The type of the document.
	 * @param sequence The ordinal sequence of the document as it appears in an envelope.
	 * @param name The name of the document.
	 * @param extension The file extension of the document.
	 * @param size The file extension of the document.
	 * @param created Date and time when the document was created.
	 * @param sourceId The Salesforce source record ID or the DocuSign template ID.
	 */
	public Document(
		final Id id,
		final String type,
		final Integer sequence,
		final String name,
		final String extension,
		final Integer size,
		final Datetime created,
		final String sourceId) {

		this.id = id;
		this.type = type;
		this.sequence = sequence;
		this.name = String.isNotBlank(name) ? name : null;
		this.extension = String.isNotBlank(extension) ? extension : null;
		this.size = size;
		this.created = created;
		this.sourceId = sourceId;
	}

	/**
	 * Factory method to construct a DocuSign envelope document from a Salesforce content version.
	 *
	 * @param contentVersion The content version from which to construct a document. This must have the
	 * <code>Title</code>, <code>FileExtension</code>, <code>Content</code>, and <code>CreatedDate</code> fields defined.
	 *
	 * @return The DocuSign envelope document representation of the content version.
	 */
	public static Document fromContentVersion(final ContentVersion contentVersion) {
		if (contentVersion == null) return null;

		return new Document(
			null,
			TYPE_FILE,
			null,
			contentVersion == null ? null : contentVersion.Title,
			contentVersion == null ? null : contentVersion.FileExtension,
			contentVersion == null ? null : contentVersion.ContentSize,
			contentVersion == null ? null : contentVersion.CreatedDate,
			contentVersion == null ? null : contentVersion.Id);
	}

	/**
	 * Factory method to construct a DocuSign envelope document from a Salesforce document.
	 *
	 * @param doc The Salesforce document from which to construct a document. This must have the <code>Name</code>,
	 * <code>Type</code>, <code>BodyLength</code>, and <code>CreatedDate</code> fields defined.
	 *
	 * @return The DocuSign envelope document representation of the Salesforce document.
	 */
	public static Document fromDocument(final Schema.Document doc) {
		if (doc == null) return null;

		return new Document(
			null,
			TYPE_DOCUMENT,
			null,
			doc == null ? null : doc.Name,
			doc == null ? null : doc.Type,
			doc == null ? null : doc.BodyLength,
			doc == null ? null : doc.CreatedDate,
			doc == null ? null : doc.Id);
	}

	/**
	 * Factory method to construct a DocuSign envelope document from a DocuSign template.
	 *
	 * @param template The DocuSign template from which to construct a document.
	 *
	 * @return The DocuSign envelope document representation of the DocuSign template.
	 */
	public static Document fromTemplate(final Template template) {
		return new Document(
			null,
			TYPE_TEMPLATE,
			null,
			template == null ? null : template.name,
			null,
			null,
			template == null ? null : template.created,
			template == null ? null : String.valueOf(template.id));
	}

	/**
	 * Representation of a Salesforce file folder.
	 */
	public class Folder {
		/**
		 * The Salesforce folder ID.
		 */
		@AuraEnabled
		public Id id { get; private set; }
		/**
		 * The Salesforce folder name.
		 */
		@AuraEnabled
		public String name { get; private set; }

		/**
		 * Constructs a folder.
		 *
		 * @param id The Salesforce folder ID.
		 * @param name The Salesforce folder name.
		 */
		public Folder(final Id id, final String name) {
			this.id = id;
			this.name = name;
		}
	}

	/**
	 * Representation of a list of Salesforce file folders and documents contained within.
	 */
	public class Folders {
		/**
		 * The list of Salesforce folders.
		 */
		@AuraEnabled
		public List<Folder> folders { get; private set; }
		/**
		 * The list of DocuSign envelope documents contained within the folders.
		 */
		@AuraEnabled
		public List<Document> documents { get; private set; }

		/**
		 * Constructs a new list of folders and documents.
		 *
		 * @param folders The list of Salesforce folders.
		 * @param documents The list of DocuSign envelope documents contained within the folders.
		 */
		public Folders(
			final List<Folder> folders,
			final List<Document> documents) {

			this.folders = folders;
			this.documents = documents;
		}
	}

	/**
	 * Creates a deep copy of the DocuSign envelope document.
	 *
	 * @return The copied DocuSign envelope document.
	 */
	public Document copy() {
		return new Document(
			null,
			this.type,
			this.sequence,
			this.name,
			this.extension,
			this.size,
			this.created,
			this.sourceId);
	}

	/**
	 * Sets the DocuSign envelope document <code>sequence</code> property.
	 *
	 * @param sequence The new sequence.
	 *
	 * @return The DocuSign envelope document with the updated <code>sequence</code> property.
	 */
	public Document withSequence(final Integer sequence) {
		this.sequence = sequence;
		return this;
	}
}
