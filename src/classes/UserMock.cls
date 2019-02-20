/**
 * Test utility methods to mock DocuSign for Salesforce users. Most service operations require either a DocuSign
 * administrator or DocuSign user context.
 */
@IsTest
global class UserMock {

	private static User administrator = null;
	private static Id systemAdministratorProfileId = null;
	private static Id standardUserProfileId = null;
	private static Id chatterFreeUserProfileId = null;
	private static Boolean createdAccountConfiguration = false;

	/**
	 * Creates a user and assigns the DocuSign Administrator permission set for unit tests. This may be used for
	 * DocuSign for Salesforce administrative methods.
	 * <p>
	 * This method also creates a test DocuSign account configuration. As such, may only be called once per test method,
	 * and it may not be combined with <code>dfsle.UserMock.createDocuSignUser</code> or
	 * <code>dfsle.UserMock.createDocuSignSender</code>.
	 *
	 * Example:
	 * <pre>
	 * static testMethod void myTest() {
	 *   dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
	 *   System.runAs(dfsle.UserMock.createDocuSignAdministrator()) {
	 *     // Call service method requiring the DocuSign Administrator permission set.
	 *   }
	 * }
	 * </pre>
	 * @return A user with the DocuSign Administrator permission set.
	 */
	global static User createDocuSignAdministrator() {
		return createDocuSignAdministrator(true);
	}

	public static User createDocuSignAdministrator(final Boolean createAccountSettings) {
		String username = UUID.randomUUID().toString();
		User u = createDocuSignAdministrator(username, null);
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID(), username);
			}
		}
		return u;
	}

	public static User createDocuSignAdministrator(final String dsUsername) {
		return createDocuSignAdministrator(dsUsername, null);
	}

	public static User createDocuSignAdministrator(final String dsUsername, final String dsPassword) {
		User u = createUser(getSystemAdministratorProfileId(), UUID.randomUUID().toString() + '@unit.test', dsUsername, true);
		if (String.isNotBlank(dsUsername)) {
			UserSettings__c us = UserSettings__c.getInstance(u.Id);
			us.Username__c = dsUsername;
			us.Password__c = dsPassword;
			upsert us;
		}
		System.runAs(getAdministrator()) {
			Permissions.assignDocuSignAdministratorPermissionSet(new Set<Id> { u.Id });
		}
		return u;
	}

	/**
	 * Creates a user and assigns the <code>DocuSign User</code> permission set for unit tests. This may be used for
	 * most DocuSign for Salesforce methods.
	 * <p>
	 * This method also creates a test DocuSign account configuration. As such, may only be called once per test method,
	 * and it may not be combined with <code>dfsle.UserMock.createDocuSignAdministrator</code> or
	 * <code>dfsle.UserMock.createDocuSignSender</code>.
	 *
	 * Example:
	 * <pre>
	 * static testMethod void myTest() {
	 *   dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
	 *   System.runAs(dfsle.UserMock.createDocuSignUser()) {
	 *     // Call service method requiring the DocuSign User permission set.
	 *   }
	 * }
	 * </pre>
	 * @return A user with the DocuSign User permission set.
	 */
	global static User createDocuSignUser() {
		return createDocuSignUser(true);
	}

	public static User createDocuSignUser(final Boolean createAccountSettings) {
		String username = UUID.randomUUID().toString();
		User u = createDocuSignUser(username, null);
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID(), username);
			}
		}
		return u;
	}

	public static User createDocuSignUser(final String dsUsername) {
		return createDocuSignUser(dsUsername, null);
	}

	public static User createDocuSignUser(final String dsUsername, final String dsPassword) {
		User u = createUser(getStandardUserProfileId(), UUID.randomUUID().toString() + '@unit.test', dsUsername, false);
		if (String.isNotBlank(dsUsername)) {
			UserSettings__c us = UserSettings__c.getInstance(u.Id);
			us.Username__c = dsUsername;
			us.Password__c = dsPassword;
			upsert us;
		}
		System.runAs(getAdministrator()) {
			Permissions.assignDocuSignUserPermissionSet(new Set<Id> { u.Id });
		}
		return u;
	}

	/**
	 * Creates a user and assigns the <code>DocuSign Sender</code> permission set for unit tests. This may be used for
	 * DocuSign for Salesforce methods that create, send, or sign envelopes.
	 * <p>
	 * This method also creates a test DocuSign account configuration. As such, may only be called once per test method,
	 * and it may not be combined with <code>dfsle.UserMock.createDocuSignAdministrator</code> or
	 * <code>dfsle.UserMock.createDocuSignUser</code>.
	 *
	 * Example:
	 * <pre>
	 * static testMethod void myTest() {
	 *   dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
	 *   System.runAs(dfsle.UserMock.createDocuSignSender()) {
	 *     // Call service method requiring the DocuSign Sender permission set.
	 *   }
	 * }
	 * </pre>
	 * @return A user with the DocuSign Sender permission set.
	 */
	global static User createDocuSignSender() {
		return createDocuSignSender(true);
	}

	public static User createDocuSignSender(final Boolean createAccountSettings) {
		String username = UUID.randomUUID().toString();
		User u = createUser(getStandardUserProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID(), username);
			}
		}
		System.runAs(getAdministrator()) {
			Permissions.assignDocuSignSenderPermissionSet(new Set<Id> { u.Id });
		}
		return u;
	}

	private static User getAdministrator() {
		if (administrator == null) {
			administrator = createAdministrator();
		}
		return administrator;
	}

	private static Id getStandardUserProfileId() {
		if (standardUserProfileId == null) {
			standardUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
		}
		return standardUserProfileId;
	}

	private static Id getSystemAdministratorProfileId() {
		if (systemAdministratorProfileId == null) {
			systemAdministratorProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
		}
		return systemAdministratorProfileId;
	}

	private static Id getChatterFreeUserProfileId() {
		if (chatterFreeUserProfileId == null) {
			chatterFreeUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User' LIMIT 1].Id;
		}
		return chatterFreeUserProfileId;
	}

	public static User createAdministrator() {
		return createUser(getSystemAdministratorProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
	}

	public static User createRestrictedUser() {
		return createUser(getChatterFreeUserProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
	}

	public static User createUser() {
		return createUser(getStandardUserProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
	}

	public static User createUser(final Id profileId, final String email, final String dsUsername,
		final Boolean canManageAccount) {

		User u = new User(
			Email = email,
			Phone = '5555555555',
			FirstName = 'UNIT',
			LastName = 'TEST',
			Username = email,
			Alias = 'test',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'ISO-8859-1',
			ProfileId = profileId,
			LanguageLocaleKey = 'en_US',
			Username__c = dsUsername,
			CanManageAccount__c = canManageAccount);
		insert u;
		return u;
	}

	public static UUID createAccountConfiguration(final UUID accountId, final String username) {
		// Tried to use AccountSettings__c.Id == null as per Salesforce documentation, but it is non-null for some
		// reason by the time it gets here.
		if (createdAccountConfiguration) throw new AssertException('DocuSign account is already configured.');

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.Environment__c = 'other';
		accountSettings.BaseUrl__c = 'https://unit.test.docusign.net/';
		accountSettings.AccountId__c = String.valueOf(accountId);
		accountSettings.AccountNumber__c = 1234;
		accountSettings.Email__c = username;
		accountSettings.Username__c = username;
		accountSettings.Password__c = UUID.randomUUID().toShortString();
		accountSettings.UseSendOnBehalfOf__c = true;
		accountSettings.EntityResolvers__c = Application.classNamespacePrefix + 'DefaultEntityResolver';
		accountSettings.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		accountSettings.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		accountSettings.CanUseSalesforceApi__c = true;
		accountSettings.UseSystemSender__c = true;
		insert accountSettings;

		insert EnvelopeSettings__c.getOrgDefaults();

		insert ChatterSettings__c.getOrgDefaults();

		insert new List<RoleSettings__c> {
			new RoleSettings__c(Name = 'Signer 1', Value__c = 1),
			new RoleSettings__c(Name = 'Signer 2', Value__c = 2),
			new RoleSettings__c(Name = 'Signer 3', Value__c = 3),
			new RoleSettings__c(Name = 'Signer 4', Value__c = 4)
		};

		insert new EnvelopeLocalization__c(
			Name = 'English',
			Language__c = 'en',
			EmailSubject__c = 'Please sign this document',
			EmailMessage__c = 'This email contains a document');

		createdAccountConfiguration = true;

		return accountId;
	}
}
