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
		if (!Permissions.isDocuSignUser()) {
			throw new UnauthorizedException(Label.MustBeDocuSignUser);
		}
		try {
			Credentials c = Credentials.getInstance();
			settings = new OrgSettings(c.account.id.toString());
		} catch (Exception ex) {
			settings = new OrgSettings('');
		}
		results.add(JSON.serialize(settings));
		return results;
	}
}

