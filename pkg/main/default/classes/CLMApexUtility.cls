public with sharing class CLMApexUtility {
	@AuraEnabled
	public static String getCurrentUserExperience() {
		try {
			return UserInfo.getUiThemeDisplayed();
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}

	@AuraEnabled(Cacheable=true)
	public static String getNamespace() {
		try {
			return Application.namespace;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Boolean verifyIsClmAdmin() {
		try {
			Permissions.verifyIsClmAdministrator();
			return true;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String getDocGenButtonLink() {
		try {			
			Url docGenUrl =  CLMService.getDocumentGenerationLink();
			return docGenUrl == null ? null : docGenUrl.toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to fetch Document Generation configuration Url');
		}
	}	
}
