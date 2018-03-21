public with sharing class DefaultDocumentResolver implements DocumentResolver {

	private static final Set<String> TYPES = new Set<String> {
		'contentversion', 'document', 'attachment'
	};

	public Boolean canResolve(final String sObjectType) {
		return String.isNotBlank(sObjectType) && TYPES.contains(sObjectType.trim().toLowerCase());
	}

	public Document resolve(final String sObjectType, final Id sObjectId) {
		Document result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			Permissions.verifyIsQueryable('ContentVersion', new List<String> {
				'Title', 'ContentSize', 'FileExtension'
			});
			List<ContentVersion> objs = [
				SELECT Title, ContentSize, FileExtension
				FROM ContentVersion
				WHERE Id = :sObjectId
				LIMIT 1
			];
			if (Collection.isNotEmpty(objs)) {
				ContentVersion obj = objs[0];
				result = new Document(null, Document.TYPE_FILE, null, obj.Title, obj.FileExtension, obj.ContentSize,
					sObjectId);
			}
		} else if (t == 'Attachment') {
			Permissions.verifyIsQueryable('Attachment', new List<String> { 'Name', 'BodyLength' });
			List<Attachment> objs = [SELECT Name, BodyLength FROM Attachment WHERE Id = :sObjectId LIMIT 1];
			if (Collection.isNotEmpty(objs)) {
				Attachment obj = objs[0];
				result = new Document(null, Document.TYPE_ATTACHMENT, null, obj.Name,
					Document.getFileExtension(obj.Name), obj.BodyLength, sObjectId);
			}
		} else if (t == 'Document') {
			Permissions.verifyIsQueryable('Document', new List<String> { 'Name', 'Type', 'BodyLength' });
			List<Schema.Document> objs = [SELECT Name, Type, BodyLength FROM Document WHERE Id = :sObjectId LIMIT 1];
			if (Collection.isNotEmpty(objs)) {
				Schema.Document obj = objs[0];
				result = new Document(null, Document.TYPE_DOCUMENT, null, obj.Name, obj.Type, obj.BodyLength,
					sObjectId);
			}
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocument_2, new List<String> {
				sObjectId, sObjectType
			}));
		}
		return result;
	}

	public Blob getBytes(String sObjectType, Id sObjectId) {
		Blob result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'ContentVersion') {
			Permissions.verifyIsQueryable('ContentVersion', new List<String> { 'VersionData' });
			List<ContentVersion> objs = [SELECT VersionData FROM ContentVersion WHERE Id = :sObjectId LIMIT 1];
			if (Collection.isNotEmpty(objs)) {
				result = objs[0].VersionData;
			}
		} else if (t == 'Attachment') {
			Permissions.verifyIsQueryable('Attachment', new List<String> { 'Body' });
			List<Attachment> objs = [SELECT Body FROM Attachment WHERE Id = :sObjectId LIMIT 1];
			if (Collection.isNotEmpty(objs)) {
				result = objs[0].Body;
			}
		} else if (t == 'Document') {
			Permissions.verifyIsQueryable('Document', new List<String> { 'Body' });
			List<Schema.Document> objs = [SELECT Body FROM Document WHERE Id = :sObjectId LIMIT 1];
			if (Collection.isNotEmpty(objs)) {
				result = objs[0].Body;
			}
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveDocument_2, new List<String> {
				sObjectId, sObjectType
			}));
		}
		return result;
	}
}
