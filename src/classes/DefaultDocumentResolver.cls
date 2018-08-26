public with sharing class DefaultDocumentResolver implements DocumentResolver {

	private static final SObjectType TYPE_CONTENT_VERSION = ContentVersion.getSObjectType();
	private static final SObjectType TYPE_DOCUMENT = Schema.Document.getSObjectType();
	private static final SObjectType TYPE_CONTENT_WORKSPACE = ContentWorkspace.getSObjectType();
	private static final SObjectType TYPE_FOLDER = Folder.getSObjectType();

	private static final Set<SObjectType> TYPES = new Set<SObjectType> {
		TYPE_CONTENT_VERSION, TYPE_DOCUMENT
	};

	public Boolean canResolveDocuments(final SObjectType type) {
		return type != null && TYPES.contains(type);
	}

	private static List<Document> getContentVersions(final Set<Id> contentVersionIds) {
		Permissions.verifyIsQueryable(TYPE_CONTENT_VERSION, new List<String> {
			'Id', 'Title', 'FileExtension', 'ContentSize', 'LastModifiedDate'
		});

		List<Document> result = new List<Document>();
		if (!Collection.isEmpty(contentVersionIds)) {
			for (ContentVersion cv : [
				SELECT Id, Title, ContentSize, FileExtension, LastModifiedDate
				FROM ContentVersion
				WHERE Id IN :contentVersionIds
				ORDER BY Id ASC
			]) {
				result.add(new Document(null, Document.TYPE_FILE, null, cv.Title, cv.FileExtension, cv.ContentSize,
					cv.LastModifiedDate, cv.Id));
			}
		}
		return result;
	}

	private static List<Document> getDocuments(final Set<Id> documentIds) {
		Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> {
			'Id', 'Name', 'Type', 'BodyLength', 'LastModifiedDate'
		});

		List<Document> result = new List<Document>();
		if (!Collection.isEmpty(documentIds)) {
			for (Schema.Document d : [
				SELECT Id, Name, Type, BodyLength, LastModifiedDate
				FROM Document
				WHERE Id IN :documentIds
				ORDER BY Id ASC
			]) {
				result.add(new Document(null, Document.TYPE_DOCUMENT, null, d.Name, d.Type, d.BodyLength,
					d.LastModifiedDate, d.Id));
			}
		}
		return result;
	}

	public List<Document> getDocuments(final SObjectType type, final Set<Id> documentIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		if (type == TYPE_CONTENT_VERSION) {
			result = getContentVersions(documentIds);
		} else if (type == TYPE_DOCUMENT) {
			result = getDocuments(documentIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}

	private static List<Document> getLinkedContentVersions(final Set<Id> linkedEntityIds,
		final Boolean getLastUpdatedOnly) {

		Permissions.verifyIsQueryable(TYPE_CONTENT_VERSION, new List<String> {
			'Id', 'Title', 'FileExtension', 'ContentSize', 'LastModifiedDate'
		});

		List<Document> documents = new List<Document>();
		if (Collection.isNotEmpty(linkedEntityIds)) {
			List<ContentDocumentLink> cdls;
			if (getLastUpdatedOnly) {
				cdls = [
					SELECT ContentDocument.LatestPublishedVersion.Id,
						ContentDocument.LatestPublishedVersion.Title,
						ContentDocument.LatestPublishedVersion.FileExtension,
						ContentDocument.LatestPublishedVersion.ContentSize,
						ContentDocument.LatestPublishedVersion.LastModifiedDate
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :linkedEntityIds
					AND ContentDocument.PublishStatus != 'U'
					AND ContentDocument.LatestPublishedVersion.ContentSize > 0
					ORDER BY ContentDocument.LatestPublishedVersion.LastModifiedDate DESC,
						ContentDocument.LatestPublishedVersion.Id DESC
					LIMIT 1
				];
			} else {
				cdls = [
					SELECT ContentDocument.LatestPublishedVersion.Id,
						ContentDocument.LatestPublishedVersion.Title,
						ContentDocument.LatestPublishedVersion.FileExtension,
						ContentDocument.LatestPublishedVersion.ContentSize,
						ContentDocument.LatestPublishedVersion.LastModifiedDate
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :linkedEntityIds
					AND ContentDocument.PublishStatus != 'U'
					AND ContentDocument.LatestPublishedVersion.ContentSize > 0
					ORDER BY ContentDocument.LatestPublishedVersion.Title
					LIMIT 100
				];
			}

			Integer sequence = 1;
			for (ContentDocumentLink cdl : cdls) {
				if (cdl != null && cdl.ContentDocument != null && cdl.ContentDocument.LatestPublishedVersion != null) {
					ContentVersion cv = cdl.ContentDocument.LatestPublishedVersion;
					documents.add(new Document(null, Document.TYPE_FILE, sequence++, cv.Title, cv.FileExtension,
						cv.ContentSize, cv.LastModifiedDate, cv.Id));
				}
			}
		}
		return documents;
	}

	public List<Document> getLinkedDocuments(final SObjectType type, final Set<Id> linkedEntityIds,
		final Boolean getLastUpdatedOnly) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		if (type == TYPE_CONTENT_VERSION) {
			result = getLinkedContentVersions(linkedEntityIds, getLastUpdatedOnly);
		} else if (type != TYPE_DOCUMENT) {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}

	private static List<Document.Folder> getContentVersionFolders() {
		Permissions.verifyIsQueryable(TYPE_CONTENT_WORKSPACE, new List<String> { 'Id', 'Name' });

		List<Document.Folder> folders = new List<Document.Folder>();
		for (ContentWorkspace f : [SELECT Id, Name FROM ContentWorkspace ORDER BY Name]) {
			folders.add(new Document.Folder(f.Id, f.Name));
		}
		return folders;
	}

	private static List<Document.Folder> getDocumentFolders() {
		Permissions.verifyIsQueryable(TYPE_FOLDER, new List<String> { 'Id', 'Name' });

		List<Document.Folder> folders = new List<Document.Folder>();
		for (Folder f : [SELECT Id, Name FROM Folder ORDER BY Name]) {
			if (String.isNotBlank(f.Name)) folders.add(new Document.Folder(f.Id, f.Name));
		}
		return folders;
	}

	public List<Document.Folder> getDocumentFolders(final SObjectType type) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document.Folder> result = null;
		if (type == TYPE_CONTENT_VERSION) {
			result = getContentVersionFolders();
		} else if (type == TYPE_DOCUMENT) {
			result = getDocumentFolders();
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> {
				String.valueOf(type)
			}));
		}
		return result;
	}

	private static List<Document> getUserContentVersions(final Set<Id> ownerIds) {
		List<Document> result = new List<Document>();
		for (ContentDocument cd : [
			SELECT LatestPublishedVersion.Id,
				LatestPublishedVersion.Title,
				LatestPublishedVersion.FileExtension,
				LatestPublishedVersion.ContentSize,
				LatestPublishedVersion.LastModifiedDate
			FROM ContentDocument
			WHERE PublishStatus = 'R' AND OwnerId IN :ownerIds
			ORDER BY LatestPublishedVersion.Title
		]) {
			ContentVersion cv = cd.LatestPublishedVersion;
			if (cv != null) {
				result.add(new Document(null, Document.TYPE_FILE, null, cv.Title, cv.FileExtension, cv.ContentSize,
					cv.LastModifiedDate, cv.Id));
			}
		}
		return result;
	}

	private static List<Document> getLibraryContentVersions(final Set<Id> libraryIds) {
		List<Document> result = new List<Document>();
		for (ContentDocument cd : [
			SELECT LatestPublishedVersion.Id,
				LatestPublishedVersion.Title,
				LatestPublishedVersion.FileExtension,
				LatestPublishedVersion.ContentSize,
				LatestPublishedVersion.LastModifiedDate
			FROM ContentDocument
			WHERE PublishStatus != 'U' AND Id IN (
				SELECT ContentDocumentId
				FROM ContentWorkspaceDoc
				WHERE ContentWorkspaceId IN :libraryIds
			)
			ORDER BY LatestPublishedVersion.Title
		]) {
			ContentVersion cv = cd.LatestPublishedVersion;
			if (cv != null) {
				result.add(new Document(null, Document.TYPE_FILE, null, cv.Title, cv.FileExtension, cv.ContentSize,
					cv.LastModifiedDate, cv.Id));
			}
		}
		return result;
	}

	private static List<Document> getFolderContentVersions(final Set<Id> folderIds) {
		Permissions.verifyIsQueryable(TYPE_CONTENT_VERSION, new List<String> {
			'Id', 'Title', 'FileExtension', 'ContentSize', 'LastModifiedDate'
		});

		List<Document> result = new List<Document>();
		if (Collection.isNotEmpty(folderIds)) {
			result.addAll(getUserContentVersions(folderIds));
			result.addAll(getLibraryContentVersions(folderIds));
		}
		return result;
	}

	private static List<Document> getFolderDocuments(final Set<Id> folderIds) {
		Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> {
			'Id', 'Name', 'Type', 'BodyLength', 'LastModifiedDate'
		});

		List<Document> result = new List<Document>();
		for (Schema.Document d : [
			SELECT Id, Name, Type, BodyLength, LastModifiedDate
			FROM Document
			WHERE FolderId IN :folderIds
			ORDER BY Name
		]) {
			result.add(new Document(null, Document.TYPE_DOCUMENT, null, d.Name, d.Type, d.BodyLength,
				d.LastModifiedDate, d.Id));
		}
		return result;
	}

	public List<Document> getFolderDocuments(final SObjectType type, final Set<Id> folderIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		if (type == TYPE_CONTENT_VERSION) {
			result = getFolderContentVersions(folderIds);
		} else if (type == TYPE_DOCUMENT) {
			result = getFolderDocuments(folderIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> {
				String.valueOf(type)
			}));
		}
		return result;
	}

	private static Map<Id, Blob> getContentVersionContent(final Set<Id> contentVersionIds) {
		Permissions.verifyIsQueryable(TYPE_CONTENT_VERSION, new List<String> { 'VersionData' });

		Map<Id, Blob> result = new Map<Id, Blob>();
		for (ContentVersion cv : [SELECT VersionData FROM ContentVersion WHERE Id IN :contentVersionIds]) {
			result.put(cv.Id, cv.VersionData);
		}
		return result;
	}

	private static Map<Id, Blob> getDocumentContent(final Set<Id> documentIds) {
		Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> { 'Body' });

		Map<Id, Blob> result = new Map<Id, Blob>();
		for (Schema.Document d : [SELECT Body FROM Document WHERE Id IN :documentIds]) {
			result.put(d.Id, d.Body);
		}
		return result;
	}

	public Map<Id, Blob> getDocumentContent(SObjectType type, Set<Id> documentIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		Map<Id, Blob> result = null;
		if (type == TYPE_CONTENT_VERSION) {
			result = getContentVersionContent(documentIds);
		} else if (type == TYPE_DOCUMENT) {
			result = getDocumentContent(documentIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> {
				String.valueOf(type)
			}));
		}
		return result;
	}
}
