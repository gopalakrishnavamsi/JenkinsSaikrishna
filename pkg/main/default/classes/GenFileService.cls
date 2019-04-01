/**
 * Methods to support management of files (ContentVersions).
 */
public with sharing class GenFileService {

	@TestVisible
	private static final GenFileService.Database DB = new GenFileService.Database();
	private static final SObjectType CONTENT_VERSION_TYPE = ContentVersion.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_LINK_TYPE = ContentDocumentLink.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_TYPE = ContentDocument.getSObjectType();

	@TestVisible
	private class Database {

		public ContentVersion createGenFile(
			final Id linkedEntityId,
			final String title,
			final String base64Data) {

			Permissions.verifyIsCreateable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'VersionData', 'IsMajorVersion', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsCreateable(CONTENT_DOCUMENT_LINK_TYPE, new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});

			ContentVersion cv = new ContentVersion(
				PathOnClient = title,
				VersionData = EncodingUtil.base64Decode(base64Data),
				IsMajorVersion = false,
				GeneratedFileFormat__c = 'Word',
				GeneratedFileSuffix__c = 'name');
			insert cv;

			cv = [
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate, GeneratedFileFormat__c, GeneratedFileSuffix__c, GeneratedFileName__c
				FROM ContentVersion
				WHERE Id = :cv.Id
				LIMIT 1
			];

			cv.GeneratedFileName__c = cv.Title;
			update cv;

			insert new ContentDocumentLink(
				ContentDocumentId = cv.ContentDocumentId,
				LinkedEntityId = linkedEntityId,
				ShareType = 'I'); // Types are: V - Viewer, C - Collaborator, and I - Inferred

			return cv;
		}

		public ContentVersion updateGenFile(
			final Id contentVersionId,
			final String base64Data) {

			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsUpdateable(CONTENT_VERSION_TYPE, new List<String> { 'VersionData' });

			ContentVersion cv = [
				SELECT VersionData
				FROM ContentVersion
				WHERE Id = :contentVersionId
				LIMIT 1
			];
			cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.base64Encode(cv.VersionData) + base64Data);
			update cv;

			return [
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate, GeneratedFileFormat__c, GeneratedFileSuffix__c, GeneratedFileName__c
				FROM ContentVersion
				WHERE Id = :contentVersionId
				LIMIT 1
			];
		}

		public Boolean deleteContentDocument(final Id contentVersionId) {
			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId'
			});
			Permissions.verifyIsQueryable(CONTENT_DOCUMENT_TYPE, new List<String> {
				'Id'
			});

			Permissions.verifyIsDeletable(CONTENT_DOCUMENT_TYPE);

			Boolean result = false;
			if (contentVersionId != null) {
				ContentVersion contentVersionInstance = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
				ContentDocument contentDocumentInstance = [SELECT Id FROM ContentDocument WHERE Id = :contentVersionInstance.ContentDocumentId];
				delete contentDocumentInstance;
				result = true;
			}
			return result;
		}
	}

	/**
	 * Saves all or part of a file.
	 *
	 * @param contentVersionId The ID of the file record to update. If <code>null</code>, the record will be created.
	 * @param linkedEntityId The ID of the Salesforce object linked to the file.
	 * @param title The file name.
	 * @param base64Data Base64-encoded file bytes. This will be appended to an existing file's data if updating.
	 *
	 * @return The created or updated file.
	 */
	public static Gen.File saveFile(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String title,
		final String base64Data) {

		// TODO: Validate arguments
		Gen.File resultFile = null;
		ContentVersion result = null;

		if (contentVersionId == null) {
			result = DB.createGenFile(linkedEntityId, title, base64Data);
		} else {
			result = DB.updateGenFile(contentVersionId, base64Data);
		}

		if (result != null) {
			resultFile = GenService.convertToGenFile(result);
		}
		return resultFile;
	}

	/**
	 * Deletes a Salesforce File. The ContentDocument is deleted from Salesforce.
	 *
	 * @param contentVersionId The ID of the ContentVersion. This will be used to fetch the ContentDocument to be deleted.
	 *
	 * @return Boolean 
	 */
	public static Boolean deleteContentDocument(final Id contentVersionId) {
		return DB.deleteContentDocument(contentVersionId);
	}

}