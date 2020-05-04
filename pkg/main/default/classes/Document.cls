/**
 * Representation of a DocuSign envelope document.
 */
global virtual class Document {
	/**
	 * DocuSign template document type constant.
	 */
	global static final String TYPE_TEMPLATE = 'Template';
	/**
	 * Salesforce file/content version document type constant.
	 */
	global static final String TYPE_FILE = 'ContentVersion';
	/**
	 * Salesforce document type constant.
	 */
	global static final String TYPE_DOCUMENT = 'Document';
	/**
	 * SpringCM repository document type constant.
	 */
	public static final String TYPE_SCM = 'SCM';

	/**
	 * The ID of the associated dfsle__Document__c record.
	 */
	@AuraEnabled
	global Id id { get; private set; }
	/**
	 * The type of the document.
	 */
	@AuraEnabled
	global String type { get; private set; }
	/**
	 * The ordinal sequence of the document as it appears in an envelope.
	 */
	@AuraEnabled
	global Integer sequence { get; private set; }
	/**
	 * The name of the document.
	 */
	@AuraEnabled
	global String name { get; private set; }
	/**
	 * The size of the document in bytes.
	 */
	@AuraEnabled
	global Integer size { get; private set; }
	/**
	 * The file extension of the document.
	 */
	@AuraEnabled
	global String extension { get; private set; }
	/**
	 * Date and time when the document was last modified.
	 */
	@AuraEnabled
	global Datetime lastModified { get; private set; }
	/**
	 * The Salesforce source record ID or the DocuSign template ID.
	 */
	@AuraEnabled
	global String sourceId { get; private set; }
	/**
	 * Whether the document properties may be modified by the sender.
	 */
	@AuraEnabled
	public Boolean readOnly { get; private set; }
	/**
	 * Whether the document can be removed from the envelope or not.
	 */
	@AuraEnabled
	public Boolean required { get; private set; }
	/**
	 * Read-only property representing the DocuSign template ID if any.
	 */
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
	 * @param id The ID of the associated dfsle__Document__c record.
	 * @param type The type of the document.
	 * @param sequence The ordinal sequence of the document as it appears in an envelope.
	 * @param name The name of the document.
	 * @param extension The file extension of the document.
	 * @param size The file extension of the document.
	 * @param lastModified Date and time when the document was created.
	 * @param sourceId The Salesforce source record ID or the DocuSign template ID.
	 * @param readOnly Whether the document properties may be modified by the sender.
	 * @param required Whether the document can be removed from the envelope or not.
	 */
	public Document(
		final Id id,
		final String type,
		final Integer sequence,
		final String name,
		final String extension,
		final Integer size,
		final Datetime lastModified,
		final String sourceId,
		final Boolean readOnly,
		final Boolean required) {

		this.id = id;
		this.type = type;
		this.sequence = sequence;
		this.name = String.isNotBlank(name) ? name : null;
		this.extension = String.isNotBlank(extension) ? extension : null;
		this.size = size;
		this.lastModified = lastModified;
		this.sourceId = sourceId;
		this.readOnly = readOnly;
		this.required = required;
	}

	/**
	 * Constructs a new DocuSign envelope document.
	 *
	 * @param id The ID of the associated dfsle__Document__c record.
	 * @param type The type of the document.
	 * @param sequence The ordinal sequence of the document as it appears in an envelope.
	 * @param name The name of the document.
	 * @param extension The file extension of the document.
	 * @param size The file extension of the document.
	 * @param lastModified Date and time when the document was created.
	 * @param sourceId The Salesforce source record ID or the DocuSign template ID.
	 */
	global Document(
		final Id id,
		final String type,
		final Integer sequence,
		final String name,
		final String extension,
		final Integer size,
		final Datetime lastModified,
		final String sourceId) {

		this(
			id,
			type,
			sequence,
			name,
			extension,
			size,
			lastModified,
			sourceId,
			false,
			false);
	}

	public Document(
		final Id id,
		final String type,
		final Integer sequence,
		final String name,
		final String extension,
		final String sourceId,
		final Boolean readOnly,
		final Boolean required) {

		this(
			id,
			type,
			sequence,
			name,
			extension,
			null,
			null,
			sourceId,
			readOnly,
			required);
	}

	/**
	 * Representation of a Salesforce file folder.
	 */
	global class Folder {
		/**
		 * The Salesforce folder ID.
		 */
		@AuraEnabled
		global Id id { get; private set; }
		/**
		 * The Salesforce folder name.
		 */
		@AuraEnabled
		global String name { get; private set; }

		/**
		 * Constructs a folder.
		 *
		 * @param id The Salesforce folder ID.
		 * @param name The Salesforce folder name.
		 */
		global Folder(final Id id, final String name) {
			this.id = id;
			this.name = name;
		}
	}

	/**
	 * Representation of a list of Salesforce file folders and documents contained within.
	 */
	global class Folders {
		/**
		 * The list of Salesforce folders.
		 */
		@AuraEnabled
		global List<Folder> folders { get; private set; }
		/**
		 * The list of DocuSign envelope documents contained within the folders.
		 */
		@AuraEnabled
		global List<Document> documents { get; private set; }

		/**
		 * Constructs a new list of folders and documents.
		 *
		 * @param folders The list of Salesforce folders.
		 * @param documents The list of DocuSign envelope documents contained within the folders.
		 */
		global Folders(
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
			this.lastModified,
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

	/**
	 * Sets the DocuSign envelope document <code>readOnly</code> and <code>required</code> properties.
	 *
	 * @param readOnly Whether the document properties may be modified by the sender.
	 * @param required Whether the document can be removed from the envelope or not.
	 *
	 * @return The DocuSign envelope document with updated <code>readOnly</code> and <code>required</code> properties.
	 */
	public Document withPermissions(
		final Boolean readOnly,
		final Boolean required) {

		this.readOnly = readOnly;
		this.required = required;
		return this;
	}

	/**
	 * Creates a DocuSign envelope document from a DocuSign template.
	 *
	 * @param docuSignId The DocuSign template ID.
	 * @param name The DocuSign template name.
	 *
	 * @return The newly-created DocuSign envelope document.
	 */
	global static Document fromTemplate(
		final UUID docuSignId,
		final String name) {

		return new Document(
			null,
			TYPE_TEMPLATE,
			null,
			name,
			null,
			null,
			null,
			String.valueOf(docuSignId),
			false,
			false);
	}

	/**
	 * Converts a DocuSign template into a DocuSign envelope document.
	 *
	 * @param template The DocuSign template from which to construct a document.
	 *
	 * @return The DocuSign envelope document representation of the DocuSign template.
	 */
	public static Document fromTemplate(final Template template) {
		if (template == null) return null;

		return new Document(
			null,
			Document.TYPE_TEMPLATE,
			null,
			template == null ? null : template.name,
			null,
			null,
			template == null ? null : template.lastModified,
			template == null ? null : String.valueOf(template.id),
			false,
		false);
	}

	/**
	 * Converts a DocuSign file into an envelope document.
	 *
	 * @param docuSignId The DocuSign file ID.
	 * @param name The DocuSign file name.
	 * @param extension The DocuSign file extension.
	 *
	 * @return The DocuSign envelope document representation of the DocuSign file.
	 */
	public static Document fromFile(
		final UUID docuSignId,
		final String name,
		final String extension) {

		return new Document(
			null,
			TYPE_SCM,
			null,
			name,
			extension,
			null,
			null,
			String.valueOf(docuSignId),
			false,
			false);
	}

	/**
	 * Converts a Salesforce content document (file) into a DocuSign envelope document. The latest published version of
	 * the file is used to construct the document.
	 *
	 * @param file The content document from which to construct a document.
	 *
	 * @return The DocuSign envelope document representation of the content version.
	 */
	public static Document fromFile(final ContentDocument file) {
		if (file == null || !file.isSet('LatestPublishedVersionId')) return null;

		ContentVersion cv = file.LatestPublishedVersion;
		return new Document(
			null,
			TYPE_FILE,
			null,
			cv.isSet('Title') ? cv.Title : null,
			cv.isSet('FileExtension') ? cv.FileExtension : null,
			cv.isSet('ContentSize') ? cv.ContentSize : null,
			cv.isSet('LastModifiedDate') ? cv.LastModifiedDate : null,
			file.Id,
			false,
			false);
	}

	/**
	 * Converts a Salesforce content version (file) into a DocuSign envelope document.
	 *
	 * @param file The content version from which to construct a document.
	 *
	 * @return The DocuSign envelope document representation of the content version.
	 */
	public static Document fromFile(final ContentVersion file) {
		if (file == null) return null;

		return new Document(
			null,
			TYPE_FILE,
			null,
			file.isSet('Title') ? file.Title : null,
			file.isSet('FileExtension') ? file.FileExtension : null,
			file.isSet('ContentSize') ? file.ContentSize : null,
			file.isSet('LastModifiedDate') ? file.LastModifiedDate : null,
			file.Id,
			false,
			false);
	}

	/**
	 * Converts a Salesforce document into a DocuSign envelope document.
	 *
	 * @param doc The Salesforce document from which to construct a document.
	 *
	 * @return The DocuSign envelope document representation of the Salesforce document.
	 */
	public static Document fromDocument(final Schema.Document doc) {
		if (doc == null) return null;

		return new Document(
			null,
			TYPE_FILE,
			null,
			doc.isSet('Name') ? doc.Name : null,
			doc.isSet('Type') ? doc.Type : null,
			doc.isSet('BodyLength') ? doc.BodyLength : null,
			doc.isSet('LastModifiedDate') ? doc.LastModifiedDate : null,
			doc.Id,
			false,
			false);
	}
}
