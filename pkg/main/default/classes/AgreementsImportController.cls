public with sharing class AgreementsImportController extends Controller {
	//FIXME : Add Test classes once the class body is locked down

	public AgreementsImportController() {
	}

	public AgreementsImportController(final ApexPages.StandardController c) {
	}

	@AuraEnabled(Cacheable = true)
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}
}