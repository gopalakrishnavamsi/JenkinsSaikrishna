public with sharing class CLMDocumentGenerationController {
	@AuraEnabled
	public static String getDocGenButtonLink() {
		try{
			Permissions.verifyIsClmUser();
			Url docGenUrl =  CLMService.getDocumentGenerationLink();
			return docGenUrl.toExternalForm();
		}catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to fetch Document Generation configuration Url');
		}
	}
}