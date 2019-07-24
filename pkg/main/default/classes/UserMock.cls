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
		User u = createDocuSignAdministrator(UUID.randomUUID());
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID());
			}
		}
		return u;
	}

	public static User createDocuSignAdministrator(final UUID dsUserId) {
		User u = createUser(getSystemAdministratorProfileId(),
			(dsUserId == null ? UUID.randomUUID().toString() : dsUserId.toString()) + '@unit.test', dsUserId, true);
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
		User u = createDocuSignUser(UUID.randomUUID());
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID());
			}
		}
		return u;
	}

	public static User createDocuSignUser(final UUID dsUserId) {
		User u = createUser(getStandardUserProfileId(),
			(dsUserId == null ? UUID.randomUUID().toString() : dsUserId.toString()) + '@unit.test', dsUserId, false);
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
		User u = createUser(getStandardUserProfileId(), UUID.randomUUID().toString() + '@unit.test', null, false);
		if (createAccountSettings) {
			System.runAs(u) {
				createAccountConfiguration(UUID.randomUUID());
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

	public static User createUser(final Id profileId, final String email, final UUID dsUserId,
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
			Username__c = String.valueOf(dsUserId),
			CanManageAccount__c = canManageAccount,
			InviteId__c = dsUserId == null ? null : UUID.randomUUID().toString(),
			InviteDate__c = dsUserId == null ? null : Date.today().addDays(-10),
			Status__c = dsUserId == null ? null : 'active');
		insert u;

		if (UUID.isNotEmpty(dsUserId)) {
			UserSettings__c s = UserSettings__c.getInstance(u.Id);
			s.AccessToken0__c = UUID.randomUUID().toShortString();
			s.AccessTokenExpires__c = Datetime.now().addHours(1);
			insert s;
		}

		return [
			SELECT Id, FirstName, LastName, Name, Email, Profile.Name, Phone, MobilePhone,
				CanManageAccount__c, InviteId__c, InviteDate__c, Status__c, Username__c
			FROM User
			WHERE Id = :u.Id
			LIMIT 1
		];
	}

	public static UUID createAccountConfiguration(final UUID accountId) {
		// Tried to use AccountSettings__c.Id == null as per Salesforce documentation, but it is non-null for some
		// reason by the time it gets here.
		if (createdAccountConfiguration) throw new AssertException('DocuSign account is already configured.');

		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.Environment__c = 'other';
		accountSettings.AccountBaseUrl__c = 'https://account.test.docusign.net/';
		accountSettings.ESignatureBaseUrl__c = 'https://esign.test.docusign.net/';
		accountSettings.ProvisioningBaseUrl__c = 'https://api.test.docusign.net/';
		accountSettings.ScmAuthBaseUrl__c = 'https://auth.test.springcm.com/';
		accountSettings.ScmApiBaseUrl__c = 'https://api.test.springcm.com/gen/';
		accountSettings.InviteCallbackUrl__c = 'https://invite.test.springcm.com/provisioning/v1/callbacks/UserInvited';
		accountSettings.InviteRedirectUrl__c = 'https://www.docusign.com/';
		accountSettings.ClientId__c = UUID.randomUUID().toString();
		accountSettings.ClientSecret__c = UUID.randomUUID().toString();
		accountSettings.PrivateKey0__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(0, 255);
		accountSettings.PrivateKey1__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(255, 255);
		accountSettings.PrivateKey2__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(510, 255);
		accountSettings.PrivateKey3__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(765, 255);
		accountSettings.PrivateKey4__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(1020, 255);
		accountSettings.PrivateKey5__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(1275, 255);
		accountSettings.PrivateKey6__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(1530, 255);
		accountSettings.PrivateKey7__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(1785, 255);
		accountSettings.PrivateKey8__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(2040, 255);
		accountSettings.PrivateKey9__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(2295, 255);
		accountSettings.PrivateKey10__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(2550, 255);
		accountSettings.PrivateKey11__c = TestUtils.TEST_RSA_PRIVATE_KEY_BASE64.mid(2805, 255);
		accountSettings.AccountId__c = String.valueOf(accountId);
		accountSettings.AccountNumber__c = TestUtils.randomInteger(1000000);
		accountSettings.AccountName__c = TestUtils.randomString(20);
		accountSettings.Email__c = (accountId == null ? UUID.randomUUID().toString() : accountId.toString()) + '@unit.test';
		accountSettings.EntityResolvers__c = Application.classNamespacePrefix + 'DefaultEntityResolver';
		accountSettings.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		accountSettings.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		accountSettings.SystemSenderId__c = UUID.randomUUID().toString();
		accountSettings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		accountSettings.AdministratorProfileId__c = TestUtils.randomInteger(1000000);
		accountSettings.SenderProfileId__c = TestUtils.randomInteger(1000000);
		accountSettings.ProductsLastChecked__c = Datetime.now();
		insert accountSettings;

		insert new List<ProductSettings__c> {
			new ProductSettings__c(
				Name = Product.NAME_ESIGNATURE,
				Status__c = Product.STATUS_ACTIVE,
				IsTrial__c = false,
				TrialExpires__c = null,
				Features__c = AccountProducts.FLAG_BULK_SENDING
					| AccountProducts.FLAG_MERGE_FIELDS
					| AccountProducts.FLAG_SIGNING_GROUPS
					| AccountProducts.FLAG_SMS_AUTHENTICATION
					| AccountProducts.FLAG_TEMPLATES),
			new ProductSettings__c(
				Name = Product.NAME_GEN,
				Status__c = Product.STATUS_ACTIVE,
				IsTrial__c = false,
				TrialExpires__c = null),
			new ProductSettings__c(
				Name = Product.NAME_NEGOTIATE,
				Status__c = Product.STATUS_ACTIVE,
				IsTrial__c = false,
				TrialExpires__c = null),
			new ProductSettings__c(
				Name = Product.NAME_CLM,
				Status__c = Product.STATUS_ACTIVE,
				IsTrial__c = false,
				TrialExpires__c = null)
		};

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

		insert new Configuration__c(
			Name = 'Gen',
			InviteEmailSubject__c = 'Invite email subject',
			InviteEmailBody__c = 'Invite email body');

		createdAccountConfiguration = true;

		return accountId;
	}
}
