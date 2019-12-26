public with sharing class UserEventsController {

	public class UserProperties {
		@AuraEnabled
		public String application { get; private set; }
		@AuraEnabled
		public String version { get; private set; }
		@AuraEnabled
		public String environment { get; private set; }
		@AuraEnabled
		public String accountIdHash { get; private set; }
		@AuraEnabled
		public String userIdHash { get; private set; }

		private UserProperties(
			final String application,
			final String version,
			final String environment,
			final String accountIdHash,
			final String userIdHash) {

			this.application = application;
			this.version = version;
			this.environment = environment;
			this.accountIdHash = accountIdHash;
			this.userIdHash = userIdHash;
		}
	}

	private static UserProperties userProperties = null;

	private static String getDocuSignUserId(final Id userId) {
		Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
			Application.namespacePrefix + 'Username__c'
		});
		User user = (User)Collection.head([SELECT Username__c FROM User WHERE Id = :userId LIMIT 1]);
		return user == null || String.isBlank(user.Username__c) ? '' : user.Username__c;
	}

	@AuraEnabled
	public static UserProperties getUserProperties() {
		try {
			if (userProperties == null) {
				AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
				userProperties = new UserProperties(
					Application.name,
					String.valueOf(Application.version),
					accountSettings.Environment__c,
					StringUtils.hash(accountSettings.AccountId__c),
					StringUtils.hash(getDocuSignUserId(UserInfo.getUserId())));
			}
			return userProperties;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get user event properties.');
		}
	}
}
