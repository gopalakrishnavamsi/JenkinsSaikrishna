public with sharing class CLMChecklist {

	@AuraEnabled
	public static String getCurrentUserExperience() {
		return CLMApexUtility.getCurrentUserExperience();
	}

	@AuraEnabled
	public static List<User_Activity__c> getProgressStatus() {
		try {
			Permissions.verifyIsClmAdministrator();
			return User_Activity__c.getall().values();
		} catch (Exception e) {
			throw Controller.wrapException(e, 'Failed to fetch the status of the onboarding progress bar');
		}

	}

	@AuraEnabled
	public static void setProgressStatus(String step) {
		try {
			Permissions.verifyIsClmAdministrator();
			User_Activity__c state=User_Activity__c.getValues(step);
			if(state==null) {
				User_Activity__c newState=new User_Activity__c();
				newState.Name=step;
				insert newState;
			}
		} catch (Exception e) {
			throw Controller.wrapException(e, 'Failed to update status of progress bar on onboarding checklist.');
		}
	}
}