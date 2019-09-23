/**
 * Methods to support management of files (ContentVersions).
 */
public with sharing class FileService {

	@TestVisible
	private static final FileService.Database DB = new FileService.Database();
	private static final SObjectType CONTENT_VERSION_TYPE = ContentVersion.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_LINK_TYPE = ContentDocumentLink.getSObjectType();

	@TestVisible
	private class Database {

		public ContentVersion createFile(
			final Id linkedEntityId,
			final String title,
			final String base64Data) {

			Permissions.verifyIsCreateable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'VersionData', 'IsMajorVersion'
			});
			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate'
			});
			Permissions.verifyIsCreateable(CONTENT_DOCUMENT_LINK_TYPE, new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});

			ContentVersion cv = new ContentVersion(
				Title = title,
				PathOnClient = title,
				VersionData = EncodingUtil.base64Decode(base64Data),
				IsMajorVersion = false);
			insert cv;

			cv = [
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate
				FROM ContentVersion
				WHERE Id = :cv.Id
				LIMIT 1
			];

			insert new ContentDocumentLink(
				ContentDocumentId = cv.ContentDocumentId,
				LinkedEntityId = linkedEntityId,
				ShareType = 'I'); // Types are: V - Viewer, C - Collaborator, and I - Inferred

			return cv;
		}

		public ContentVersion updateFile(
			final Id contentVersionId,
			final String base64Data) {

			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate'
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
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate
				FROM ContentVersion
				WHERE Id = :contentVersionId
				LIMIT 1
			];
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
	public static ContentVersion saveFile(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String title,
		final String base64Data) {

		// TODO: Validate arguments

		ContentVersion result = null;

		if (contentVersionId == null) {
			result = DB.createFile(linkedEntityId, title, base64Data);
		} else {
			result = DB.updateFile(contentVersionId, base64Data);
		}

		return result;
	}

	/**
	 * Retrieves a esign deeplink URL.
	 * The caller must be the a docusign user
	 *
	 * @param sourceId source record id
	 * @param fileIds file/contentdocumentid list
	 *
	 * @return sending deeplink url
	 */
	public static Url getSendingDeepLink(Id sourceId, String fileIdsInCommaSeparated) {
		try {
			Permissions.verifyIsDocuSignUser();
			PageReference sendingPath = Page.Sending;
			if (sourceId != null) {
				sendingPath.getParameters().put('sId', EncodingUtil.urlEncode(sourceId, StringUtils.ENCODING));
			}
			if (fileIdsInCommaSeparated != null) {
				sendingPath.getParameters().put('files', EncodingUtil.urlEncode(fileIdsInCommaSeparated, StringUtils.ENCODING));
			}
			return new Url(Salesforce.baseUrl, sendingPath.getUrl());
		} catch (Exception ex) {
			throw new APIException(ex.getMessage());
		}
	}
}