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
}