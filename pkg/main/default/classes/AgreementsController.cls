public with sharing class AgreementsController extends Controller {

	public AgreementsController() {
	}

	public AgreementsController(final ApexPages.StandardController c) {
	}

	@AuraEnabled(Cacheable = true)
	public static String getNameSpace() {
		return Application.lightningNamespace;
	}
}