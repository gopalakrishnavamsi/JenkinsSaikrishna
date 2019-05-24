global with sharing class OrgService {

	@TestVisible
	private class OrgSettings {
		@TestVisible
		private String accountId;

		public OrgSettings(final String accountId) {
			this.accountId = accountId;
		}
	}

	@InvocableMethod
	global static List<String> getOrgSettings() {
		List<String> results = new List<String>();
		OrgSettings settings;
		if (Permissions.isDocuSignUser()) {
			try {
				settings = new OrgSettings(AccountSettings__c.getOrgDefaults().AccountId__c);
			} catch (Exception ex) {
				settings = new OrgSettings('');
				LoggerService.getInstance().exception(ex, 'getOrgSettings');
			}
		} else {
			throw new UnauthorizedException(Label.MustBeDocuSignUser);
		}
		results.add(JSON.serialize(settings));
		return results;
	}
}

