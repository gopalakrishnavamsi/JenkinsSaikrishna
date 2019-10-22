/* Contains global invocable method used by SpringCM platform for SpringCM Salseforce OAuth
 * 	A single class can only have one Invocable method
 */
/**
 * Used internally by DocuSign.
 */
global with sharing class OrgService {

	@TestVisible
	private class OrgSettings {
		@TestVisible
		private String accountId;

		public OrgSettings(final String accountId) {
			this.accountId = accountId;
		}
	}

	/*
	 * Used by SpringCM platform during setup of Salesforce SpringCM OAuth in order to validate the DocuSign Account Id
	 * The method is marked as global and decorated with the InvocableMethod attribute to allow SpringCM platform to invoke this method
	 *
	 * @param none
	 *
	 * @return returns a List<String> where every entry corresponds to a JSON string having the account id details.
	 * The size of returned list should be ideally 1
	 *
	 */
	/**
	 * Used internally by DocuSign.
	 *
	 * @return
	 */
	@InvocableMethod
	global static List<String> getOrgSettings() {
		List<String> results = new List<String>();
		OrgSettings settings;
		Permissions.verifyIsDocuSignUser();
		try {
			settings = new OrgSettings(AccountSettings__c.getOrgDefaults().AccountId__c);
		} catch (Exception ex) {
			settings = new OrgSettings('');
			LoggerService.getInstance().exception(ex, 'getOrgSettings');
		}
		results.add(JSON.serialize(settings));
		return results;
	}

}

