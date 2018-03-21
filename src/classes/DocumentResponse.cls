public with sharing class DocumentResponse extends RemoteActionResponse {

	public List<Document.Folder> folders { get; private set; }
	public List<Document> documents { get; private set; }
	public List<CustomField> customFields { get; private set; }

	private DocumentResponse(
		final Boolean success,
		final List<APIError> errors,
		final List<Document.Folder> folders,
		final List<Document> documents,
		final List<CustomField> customFields) {

		super(success, errors);

		this.folders = folders;
		this.documents = documents;
		this.customFields = customFields;
	}

	public static DocumentResponse failure(final Exception ex) {
		return failure(new List<APIError> { APIError.fromException(ex) });
	}

	public static DocumentResponse failure(final List<APIError> errors) {
		return new DocumentResponse(false, errors, null, null, null);
	}

	public static DocumentResponse success(final Document.Folders folders) {
		return new DocumentResponse(true, null, folders.folders, folders.documents,
			null);
	}

	public static DocumentResponse success(final List<Document> documents) {
		return new DocumentResponse(true, null, null, documents, null);
	}

	public static DocumentResponse success(
		final List<Document> documents,
		final List<CustomField> customFields) {

		return new DocumentResponse(true, null, null, documents, customFields);
	}
}
