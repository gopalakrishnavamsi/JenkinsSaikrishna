public class Document {

	public static final String TYPE_TEMPLATE = 'Template';
	public static final String TYPE_FILE = 'ContentVersion';
	public static final String TYPE_DOCUMENT = 'Document';

	public Id id { get; private set; }
	public String type { get; private set; }
	public Integer sequence { get; private set; }
	public String name { get; private set; }
	public Integer size { get; private set; }
	public String extension { get; private set; }
	public String sourceId { get; private set; }
	public UUID templateId {
		get {
			if (String.isNotBlank(this.sourceId) && this.type == TYPE_TEMPLATE) {
				return UUID.tryParse(this.sourceId);
			}
			return null;
		}
	}

	public Document(
		final Id id,
		final String type,
		final Integer sequence,
		final String name,
		final String extension,
		final Integer size,
		final String sourceId) {

		this.id = id;
		this.type = type;
		this.sequence = sequence;
		this.name = String.isNotBlank(name) ? name : null;
		this.extension = String.isNotBlank(extension) ? extension : null;
		this.size = size;
		this.sourceId = sourceId;
	}

	public static Document fromContentVersion(final ContentVersion contentVersion) {
		if (contentVersion == null) return null;

		return new Document(
			null,
			TYPE_FILE,
			null,
			contentVersion == null ? null : contentVersion.Title,
			contentVersion == null ? null : contentVersion.FileExtension,
			contentVersion == null ? null : contentVersion.ContentSize,
			contentVersion == null ? null : contentVersion.Id);
	}

	public static Document fromDocument(final Schema.Document doc) {
		if (doc == null) return null;

		return new Document(
			null,
			TYPE_DOCUMENT,
			null,
			doc == null ? null : doc.Name,
			doc == null ? null : doc.Type,
			doc == null ? null : doc.BodyLength,
			doc == null ? null : doc.Id);
	}

	public static Document fromTemplate(final Template template) {
		return new Document(
			null,
			TYPE_TEMPLATE,
			null,
			template == null ? null : template.name,
			null,
			null,
			template == null ? null : String.valueOf(template.id));
	}

	public class Folder {
		public Id id { get; private set; }
		public String name { get; private set; }

		public Folder(final Id id, final String name) {
			this.id = id;
			this.name = name;
		}
	}

	public class Folders {
		public List<Folder> folders { get; private set; }
		public List<Document> documents { get; private set; }

		public Folders(
			final List<Folder> folders,
			final List<Document> documents) {

			this.folders = folders;
			this.documents = documents;
		}
	}

	public Document withSequence(final Integer sequence) {
		this.sequence = sequence;
		return this;
	}
}
