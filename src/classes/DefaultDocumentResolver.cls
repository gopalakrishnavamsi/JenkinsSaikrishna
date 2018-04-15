public with sharing class DefaultDocumentResolver implements DocumentResolver {

	private static final Set<String> TYPES = new Set<String> {
		'contentversion', 'document'
	};

	public Boolean canResolveDocument(final String sObjectType) {
		return String.isNotBlank(sObjectType) && TYPES.contains(sObjectType.trim().toLowerCase());
	}

	private static List<Document> getContentVersions(final Set<Id> contentVersionIds) {
		Permissions.verifyIsQueryable('ContentVersion', new List<String> { 'Title', 'ContentSize', 'FileExtension' });

		List<Document> result = new List<Document>();
		for (ContentVersion cv : [SELECT Title, ContentSize, FileExtension FROM ContentVersion WHERE Id IN :contentVersionIds]) {
			result.add(new Document(null, Document.TYPE_FILE, null, cv.Title, cv.FileExtension, cv.ContentSize, cv.Id));
		}
		return result;
	}

	private static List<Document> getDocuments(final Set<Id> documentIds) {
		Permissions.verifyIsQueryable('Document', new List<String> { 'Name', 'Type', 'BodyLength' });

		List<Document> result = new List<Document>();
		for (Schema.Document d : [SELECT Name, Type, BodyLength FROM Document WHERE Id IN :documentIds]) {
			result.add(new Document(null, Document.TYPE_DOCUMENT, null, d.Name, d.Type, d.BodyLength, d.Id));
		}
		return result;
	}

	public List<Document> getDocuments(final String sObjectType, final Set<Id> sObjectIds) {
		List<Document> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			result = getContentVersions(sObjectIds);
		} else if (t == 'Document') {
			result = getDocuments(sObjectIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> { sObjectType }));
		}
		return result;
	}

	private static List<Document.Folder> getContentVersionFolders() {
		Permissions.verifyIsQueryable('ContentWorkspace', new List<String> { 'Id', 'Name' });

		List<Document.Folder> folders = new List<Document.Folder>();
		for (ContentWorkspace f : [SELECT Id, Name FROM ContentWorkspace ORDER BY Name]) {
			folders.add(new Document.Folder(f.Id, f.Name));
		}
		return folders;
	}

	private static List<Document.Folder> getDocumentFolders() {
		Permissions.verifyIsQueryable('Folder', new List<String> { 'Id', 'Name' });

		List<Document.Folder> folders = new List<Document.Folder>();
		for (Folder f : [SELECT Id, Name FROM Folder ORDER BY Name]) {
			if (String.isNotBlank(f.Name)) folders.add(new Document.Folder(f.Id, f.Name));
		}
		return folders;
	}

	public List<Document.Folder> getDocumentFolders(final String sObjectType) {
		List<Document.Folder> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			result = getContentVersionFolders();
		} else if (t == 'Document') {
			result = getDocumentFolders();
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> { sObjectType }));
		}
		return result;
	}

	private static List<Document> getUserContentVersions(final Set<Id> ownerIds) {
		List<Document> result = new List<Document>();
		for (ContentDocument cd : [
			SELECT LatestPublishedVersion.Id,
				LatestPublishedVersion.Title,
				LatestPublishedVersion.FileExtension,
				LatestPublishedVersion.ContentSize
			FROM ContentDocument
			WHERE PublishStatus = 'R' AND OwnerId IN :ownerIds
			ORDER BY LatestPublishedVersion.Title
		]) {
			ContentVersion cv = cd.LatestPublishedVersion;
			if (cv != null) {
				result.add(new Document(null, Document.TYPE_FILE, null, cv.Title, cv.FileExtension, cv.ContentSize,
					cv.Id));
			}
		}
		return result;
	}

	private static List<Document> getLibraryContentVersions(final Set<Id> libraryIds) {
		List<Document> result = new List<Document>();
		for (ContentDocument cd : [
			SELECT LatestPublishedVersion.Id, LatestPublishedVersion.Title, LatestPublishedVersion.FileExtension,
				LatestPublishedVersion.ContentSize
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
					cv.Id));
			}
		}
		return result;
	}

	private static List<Document> getFolderContentVersions(final Set<Id> folderIds) {
		Permissions.verifyIsQueryable('ContentVersion', new List<String> { 'Id', 'Title', 'FileExtension', 'ContentSize' });

		List<Document> result = new List<Document>();
		if (Collection.isNotEmpty(folderIds)) {
			result.addAll(getUserContentVersions(folderIds));
			result.addAll(getLibraryContentVersions(folderIds));
		}
		return result;
	}

	private static List<Document> getFolderDocuments(final Set<Id> folderIds) {
		Permissions.verifyIsQueryable('Document', new List<String> { 'Id', 'Name', 'Type', 'BodyLength' });

		List<Document> result = new List<Document>();
		for (Schema.Document d : [SELECT Id, Name, Type, BodyLength FROM Document WHERE FolderId IN :folderIds ORDER BY Name]) {
			result.add(new Document(null, Document.TYPE_DOCUMENT, null, d.Name, d.Type, d.BodyLength, d.Id));
		}
		return result;
	}

	public List<Document> getFolderDocuments(final String sObjectType, final Set<Id> folderIds) {
		List<Document> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			result = getFolderContentVersions(folderIds);
		} else if (t == 'Document') {
			result = getFolderDocuments(folderIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> { sObjectType }));
		}
		return result;
	}

	private static Map<Id, Blob> getContentVersionContent(final Set<Id> contentVersionIds) {
		Permissions.verifyIsQueryable('ContentVersion', new List<String> { 'VersionData' });

		Map<Id, Blob> result = new Map<Id, Blob>();
		for (ContentVersion cv : [SELECT VersionData FROM ContentVersion WHERE Id IN :contentVersionIds]) {
			result.put(cv.Id, cv.VersionData);
		}
		return result;
	}

	private static Map<Id, Blob> getDocumentContent(final Set<Id> documentIds) {
		Permissions.verifyIsQueryable('Document', new List<String> { 'Body' });

		Map<Id, Blob> result = new Map<Id, Blob>();
		for (Schema.Document d : [SELECT Body FROM Document WHERE Id IN :documentIds]) {
			result.put(d.Id, d.Body);
		}
		return result;
	}

	public Map<Id, Blob> getDocumentContent(String sObjectType, Set<Id> sObjectIds) {
		Map<Id, Blob> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			result = getContentVersionContent(sObjectIds);
		} else if (t == 'Document') {
			result = getDocumentContent(sObjectIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocumentType_1, new List<String> { sObjectType }));
		}
		return result;
	}
}
