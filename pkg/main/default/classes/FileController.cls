public with sharing class FileController extends Controller {

	@AuraEnabled
	public static ContentVersion saveChunk(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String fileName,
		final String base64Data) {

		try {
			return FileService.saveFile(contentVersionId, linkedEntityId, fileName, StringUtils.decode(base64Data));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save file chunk');
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<ContentDocument> getFilesOwnedByUser(Integer offset, Integer size) {
		try {
			return FileService.getFilesOwnedByUser(offset, size);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get files owned by user');
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<ContentDocument> getFilesSharedWithUser(Integer offset, Integer size) {
		try {
			return FileService.getFilesSharedWithUser(offset, size);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get files shared with user');
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<ContentDocument> getFilesRecentlyViewedByUser(Integer count) {
		try {
			return FileService.getFilesRecentlyViewedByUser(count);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get files recently viewed by user');
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<ContentDocument> getFilesFollowedByUser(Integer offset, Integer size) {
		try {
			return FileService.getFilesFollowedByUser(offset, size);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get files followed by user');
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<ContentWorkspace> getContentWorkspaces(Integer offset, Integer size) {
		try {
			return FileService.getContentWorkspaces(offset, size);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get content workspaces');
		}
	}

	@AuraEnabled
	public static List<ContentDocument> getContentDocumentsInWorkspace(Integer offset, Integer size, Id contentWorkspaceId) {
		try {
			return FileService.getContentDocumentsInWorkspace(offset, size, contentWorkspaceId);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get content documents in workspace');
		}
	}

	@AuraEnabled
	public static void linkContentDocuments(List<Id> contentDocumentIds, Id sourceObjectId) {
		try {
			FileService.linkContentDocuments(contentDocumentIds, sourceObjectId);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to link content documents');
		}
	}
}