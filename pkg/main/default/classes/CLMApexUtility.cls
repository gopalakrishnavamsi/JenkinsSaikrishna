public with sharing class CLMApexUtility {
	@AuraEnabled
    public static String getCurrentUserExperience(){
        try {
            Permissions.verifyIsClmAdministrator();
            return UserInfo.getUiThemeDisplayed();
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }        
    }
    @AuraEnabled(Cacheable=true)
    public static String getNamespace(){
		try {
            Permissions.verifyIsClmAdministrator();
			return Application.namespace;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}
}