public with sharing class FileController extends Controller {

	@AuraEnabled
	public static Id saveChunk(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String fileName,
		final String base64Data) {

		try {
			return FileService.saveFile(contentVersionId, linkedEntityId, fileName, StringUtils.decode(base64Data)).Id;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save file chunk');
		}
	}
}
