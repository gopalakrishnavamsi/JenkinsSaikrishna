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
}