public with sharing class FileController extends Controller {

	public Boolean uploadFinished { get; set; }
	public Id contentDocumentId { get; set; }
	public String contentDocumentTitle { get; set; }
	public String message { get; set; }
	public String messageType { get; set; }
	public transient ContentVersion contentVersion;

	public FileController() {
		this.uploadFinished = false;
	}

	@AuraEnabled
	public static String getVisualForceHost() {
		return Salesforce.getVisualforceHost();
	}

	// Use getter so we can make contentVersion transient
	public ContentVersion getContentVersion() {
		contentVersion = new ContentVersion();
		return contentVersion;
	}

	public void uploadFile() {
		try {
			Permissions.verifyIsCreateable(Schema.ContentVersion.getSObjectType(), new List<String> {
				'ContentDocumentId', 'Title'
			});
			Permissions.verifyIsCreateable(ContentDocumentLink.getSObjectType(), new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});

			Id recordId = (Id)ApexPages.currentPage().getParameters().get('Id');

			insert contentVersion;

			ContentVersion insertedContentVersion = [
				SELECT Id, ContentDocumentId, ContentDocument.Title
				FROM ContentVersion
				WHERE Id = :contentVersion.Id
				LIMIT 1
			];
			contentDocumentId = insertedContentVersion.ContentDocumentId;
			contentDocumentTitle = insertedContentVersion.ContentDocument.Title;

			insert new ContentDocumentLink(
				ContentDocumentId = insertedContentVersion.ContentDocumentId,
				LinkedEntityId = recordId,
				ShareType = 'V'); //meaning Viewer, other types are: C - Collaborator and I - Inferred

			message = Label.UploadSuccessful;
			messageType = 'SUCCESS';
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Failed to upload file');

			List<ApexPages.Message> apexPageMessagesList = ApexPages.getMessages();
			for (ApexPages.Message apexPageMessage : apexPageMessagesList) {
				String apexPageMessageString = String.valueOf(apexPageMessage);
				if (apexPageMessageString.contains(Label.FileSizeLimitReached)) {
					message = Label.FileSizeLimit;
				}
			}

			if (String.isEmpty(message)) {
				message = Label.SomethingWrong;
			}
			messageType = 'ERROR';
		} finally {
			uploadFinished = true;
		}
	}
}
