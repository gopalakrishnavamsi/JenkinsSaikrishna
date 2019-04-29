public with sharing class AgreementsController extends Controller {
	//FIXME : Add Test classes once the class body is locked down
	public AgreementsController() {
	}

	public AgreementsController(final ApexPages.StandardController c) {
	}

	@AuraEnabled(Cacheable = true)
	public static String getNameSpace() {
		return Application.lightningNamespace;
	}

	@AuraEnabled
	public static List<Agreement> getAgreements(final Id sourceObjectId) {
		try {
			return NegotiateService.getAgreements(sourceObjectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreements.');
		}

	}

	@AuraEnabled
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus createAgreementInEOSFolder(final Id sfContentVersionId, final Id sourceObjectId, final String documentName) {
		try {
			return NegotiateService.createAgreementInEOSFolder(sfContentVersionId, sourceObjectId, documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create Agreement Folder');
		}
	}

	@AuraEnabled
	public static Boolean renameAgreement(final String documentId, final String documentName) {
		try {
			return NegotiateService.renameAgreement(UUID.parse(documentId), documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Rename Agreement');
		}
	}

	@AuraEnabled
	public static Boolean deleteAgreement(final String documentId) {
		try {
			return NegotiateService.deleteAgreement(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Delete Agreement');
		}
	}
}