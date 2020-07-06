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
	 * @param files scm file/contentdocumentid list
	 *
	 * @return sending deeplink url
	 */
	public static PageReference getSendingDeepLink(
		final Id sourceId,
		final List<String> files) {

		Permissions.verifyIsDocuSignUser();

		PageReference sendingPath = Page.Sending;
		if (String.isNotBlank(sourceId)) {
			sendingPath.getParameters().put('sId', sourceId);
		}
		if (Collection.isNotEmpty(files)) {
			sendingPath.getParameters().put('files', String.join(files, ','));
		}
		return sendingPath;
	}

	//todo :  Generalize a service method to handle different filter types
	/**
	 * Retrieves all files owned by the logged in user
	 * @param offset - offset from where the records should be returned
	 * @param size - count of records requested
	 * @return List<ContentDocument>
	 */
	public static List<ContentDocument> getFilesOwnedByUser(Integer offset, Integer size) {
		Permissions.verifyIsDocuSignUser();
		return [
			SELECT Id, Title, FileType, FileExtension, ContentSize
			FROM ContentDocument
			WHERE OwnerId = :UserInfo.getUserId()
			WITH SECURITY_ENFORCED
			ORDER BY LastModifiedDate DESC
			LIMIT :size
			OFFSET :offset
		];
	}

	/**
	 * Retrieves all files shared with the logged in user
	 * @param offset - offset from where the records should be returned
	 * @param size - count of records requested
	 * @return List<ContentDocument>
	 */
	public static List<ContentDocument> getFilesSharedWithUser(Integer offset, Integer size) {
		Permissions.verifyIsDocuSignUser();
		List<Id> contentDocIds = new List<Id>();
		for (ContentDocumentLink cdl : [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :UserInfo.getUserId()
			AND ShareType != 'I'
			WITH SECURITY_ENFORCED
			LIMIT :size
			OFFSET :offset
		]) {
			contentDocIds.add(cdl.ContentDocumentId);
		}
		return getContentDocuments(contentDocIds);
	}

	/**
	 * Retrieves all files recently viewed by the logged in user
	 * @param count - count of records requested
	 * @return List<ContentDocument>
	 */
	public static List<ContentDocument> getFilesRecentlyViewedByUser(Integer count) {
		Permissions.verifyIsDocuSignUser();
		return [
			SELECT Id, Title, FileType, FileExtension, ContentSize
			FROM ContentDocument
			WHERE LastViewedDate != NULL
			WITH SECURITY_ENFORCED
			ORDER BY LastViewedDate DESC
			LIMIT :count
		];
	}

	/**
	 * Retrieves all files followed by the logged in user
	 * @param offset - offset from where the records should be returned
	 * @param size - count of records requested
	 * @return List<ContentDocument>
	 */
	public static List<ContentDocument> getFilesFollowedByUser(Integer offset, Integer size) {
		Permissions.verifyIsDocuSignUser();
		List<Id> contentDocIds = new List<Id>();
		for (EntitySubscription es : [
			SELECT ParentId
			FROM EntitySubscription
			WHERE SubscriberId = :UserInfo.getUserId()
			AND Parent.Type = 'ContentDocument'
			ORDER BY CreatedDate DESC
			LIMIT :size
			OFFSET :offset
		]) {
			contentDocIds.add(es.ParentId);
		}
		return getContentDocuments(contentDocIds);
	}

	/**
	 * Retrieves all ContentWorkspaces
	 * @param offset - offset from where the records should be returned
	 * @param size - count of records requested
	 * @return List<ContentWorkspace>
	 */
	public static List<ContentWorkspace> getContentWorkspaces(Integer offset, Integer size) {
		Permissions.verifyIsDocuSignUser();
		return [
			SELECT Id, Name
			FROM ContentWorkspace
			WITH SECURITY_ENFORCED
			ORDER BY LastModifiedDate DESC
			LIMIT :size
			OFFSET :offset
		];
	}

	/**
	 * Retrieves all ContentDocuments within a ContentWorkspace
	 * @param offset - offset from where the records should be returned
	 * @param size - count of records requested
	 * @param contentWorkspaceId - id of the contentWorkspace
	 * @return List<ContentDocument>
	 */
	public static List<ContentDocument> getContentDocumentsInWorkspace(Integer offset, Integer size, Id contentWorkspaceId) {
		Permissions.verifyIsDocuSignUser();
		List<Id> contentDocIds = new List<Id>();
		for (ContentWorkspaceDoc cwd : [
			SELECT Id, ContentDocumentId
			FROM ContentWorkspaceDoc
			WHERE ContentWorkspaceId = :contentWorkspaceId
			WITH SECURITY_ENFORCED
			LIMIT :size
			OFFSET :offset
		]) {
			contentDocIds.add(cwd.ContentDocumentId);
		}
		return getContentDocuments(contentDocIds);
	}

	/**
	 * Links the provided Content Documents with the Source Object
	 * @param List<Id> contentDocumentIds - list of Content Document Ids
	 * @param Id sourceObjectId - Source Record Id to which the document has to be linked
	 * @return List<ContentDocumentLink>
	 */
	public static String linkContentDocuments(List<Id> contentDocumentIds, Id sourceObjectId) {
		Permissions.verifyIsDocuSignUser();
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (Id id : contentDocumentIds) {
			ContentDocumentLink cdl = new ContentDocumentLink(
				ContentDocumentId = id,
				LinkedEntityId = sourceObjectId,
				ShareType = 'V'
			);
			contentDocumentLinks.add(cdl);
		}
		Database.SaveResult[] srList = System.Database.insert(contentDocumentLinks, false);
		Integer successCount = 0;
		Integer errorCount = 0;
		String errorMessage = '';
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				successCount++;
			} else {
				errorCount++;
				for (Database.Error err : sr.getErrors()) {
					if (errorMessage == '') {
						errorMessage = err.getMessage();
					} else if (errorMessage != '' && err.getMessage().contains(errorMessage)) {
						continue;
					} else {
						errorMessage += ', ' + err.getMessage();
					}
				}
			}
		}
		if (errorMessage != '') {
			String additionalMsg = successCount + ' file(s) were added successfully. ' +
				errorCount + ' files(s) failed to add.';
			return errorMessage + ' ' + additionalMsg;
		}
		return null;
	}

	private static List<ContentDocument> getContentDocuments(List<Id> contentDocumentIds) {
		return [
			SELECT Id, Title, FileType, FileExtension, ContentSize
			FROM ContentDocument
			WHERE Id IN:contentDocumentIds
			WITH SECURITY_ENFORCED
			ORDER BY LastModifiedDate DESC
		];
	}

}
