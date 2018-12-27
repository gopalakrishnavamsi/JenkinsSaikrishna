@IsTest
private class CredentialsTest {

	@IsTest
	static void test_getAccountCredentials() {
		UUID accountId = UUID.randomUUID();
		UserMock.createAccountConfiguration(accountId);

		Test.startTest();
		Credentials.AccountCredentials result1 = Credentials.getAccountCredentials();
		Credentials.AccountCredentials result2 = Credentials.getAccountCredentials();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(accountId, result1.accountId);

		System.assert(result2 === result1);
	}

	@IsTest
	static void test_getUserCredentials() {
		User u1 = UserMock.createUser();
		User u2 = UserMock.createUser();

		Test.startTest();
		Credentials.UserCredentials result1 = Credentials.getUserCredentials(u1.Id);
		Credentials.UserCredentials result2 = Credentials.getUserCredentials(u1.Id);
		Credentials.UserCredentials result3 = Credentials.getUserCredentials(u2.Id);
		Credentials.UserCredentials result4 = Credentials.getUserCredentials(u2.Id);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(u1.Username__c, String.valueOf(result1.userId));

		System.assert(result2 === result1);

		System.assert(result3 !== result1);
		System.assertNotEquals(null, result3);
		System.assertEquals(u2.Username__c, String.valueOf(result3.userId));

		System.assert(result4 === result3);
	}

	@IsTest
	static void test_buildAPICredentials() {
		UUID accountId = UUID.randomUUID();
		String ae = UUID.randomUUID().toString() + '@unit.test';
		Url aUrl = new Url('https://account.test.docusign.com/');
		Url eUrl = new Url('https://esign.test.docusign.net/');
		Credentials.AccountCredentials ac1 = new Credentials.AccountCredentials(
			DocuSign.Environment.Demo, aUrl, eUrl, accountId, 1111L, 'Account 1', ae, null);
		UUID ssId = UUID.randomUUID();
		Credentials.AccountCredentials ac2 = new Credentials.AccountCredentials(
			DocuSign.Environment.Demo, aUrl, eUrl, accountId, 2222L, 'Account 2', ae, ssId);
		Credentials.UserCredentials uc = new Credentials.UserCredentials(
			UUID.randomUUID(), true, new Credentials.AccessToken(UUID.randomUUID().toString(), Datetime.now().addHours(1)));

		Test.startTest();
		Credentials result1 = Credentials.buildAPICredentials(ac1, uc);
		Credentials result2 = Credentials.buildAPICredentials(ac2, uc);
		// System sender tests
		Credentials result3 = Credentials.buildAPICredentials(ac1, null);
		Credentials result4 = Credentials.buildAPICredentials(ac2, null);
		try {
			Credentials.buildAPICredentials(null, uc);
			throw new AssertException('Expected buildAPICredentials to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.ConfigurationError, ex.getMessage());
		}
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertEquals(DocuSign.Environment.Demo, result1.environment);
		System.assertNotEquals(null, result1.accountBaseUrl);
		System.assertEquals(aUrl.toExternalForm(), result1.accountBaseUrl.toExternalForm());
		System.assertNotEquals(null, result1.eSignatureBaseUrl);
		System.assertEquals(eUrl.toExternalForm(), result1.eSignatureBaseUrl.toExternalForm());
		System.assertEquals(accountId, result1.accountId);
		System.assertEquals(1111L, result1.accountNumber);
		System.assertEquals('Account 1', result1.accountName);
		System.assertEquals(ae, result1.email);
		System.assertEquals(uc.userId, result1.userId);
		System.assertNotEquals(null, result1.token);
		System.assertEquals(uc.token.token, result1.token.token);
		System.assertEquals(uc.token.expires, result1.token.expires);

		System.assertNotEquals(null, result2);
		System.assert(result2.isValid);
		System.assertEquals(DocuSign.Environment.Demo, result2.environment);
		System.assertNotEquals(null, result2.accountBaseUrl);
		System.assertEquals(aUrl.toExternalForm(), result2.accountBaseUrl.toExternalForm());
		System.assertNotEquals(null, result2.eSignatureBaseUrl);
		System.assertEquals(eUrl.toExternalForm(), result2.eSignatureBaseUrl.toExternalForm());
		System.assertEquals(accountId, result2.accountId);
		System.assertEquals(2222L, result2.accountNumber);
		System.assertEquals('Account 2', result2.accountName);
		System.assertEquals(ae, result2.email);
		System.assertEquals(uc.userId, result2.userId);
		System.assertNotEquals(null, result2.token);
		System.assertEquals(uc.token.token, result2.token.token);
		System.assertEquals(uc.token.expires, result2.token.expires);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isValid); // No user or system sender

		System.assertNotEquals(null, result4);
		System.assert(result4.isValid);
		System.assertEquals(ssId, result4.userId);
	}

	@IsTest
	static void test_getInstance_default() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Test.startTest();
			Credentials result1 = Credentials.getInstance();
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assert(result2 === result1);
		}
	}

	@IsTest
	static void test_getInstance_user() {
		User u1 = UserMock.createDocuSignUser(false);
		User u2 = UserMock.createDocuSignUser(false);

		System.runAs(u1) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Test.startTest();
			Credentials result1 = Credentials.getInstance(u1.Id, true);
			Credentials result2 = Credentials.getInstance(u1.Id, true);
			Credentials result3 = Credentials.getInstance(u2.Id, true);
			Credentials result4 = Credentials.getInstance(u2.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
			System.assert(result2 === result1);

			System.assertNotEquals(null, result3);
			System.assert(result3.isValid);
			System.assert(result3 !== result1);

			System.assertNotEquals(null, result4);
			System.assert(result4.isValid);
			System.assert(result4 !== result3);
		}
	}

	@IsTest
	static void test_getInstance_error() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				Credentials.getInstance(UserInfo.getUserId(), true);
				throw new AssertException('Expected getInstance to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getInstance_invalid_user() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.SystemSenderId__c = null;
			update s;

			Test.startTest();
			try {
				Credentials.getInstance(UserMock.createUser().Id, true);
				throw new AssertException('Expected getInstance to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeActivated, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getInstance_system_sender() {
		User u1 = UserMock.createUser();
		User u2 = UserMock.createUser();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().SystemSenderId__c);

			Test.startTest();
			Credentials result1 = Credentials.getInstance(u1.Id, true);
			Credentials result2 = Credentials.getInstance(u2.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
		}
	}

	@IsTest
	static void test_getToken() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = 'unit.test';
			s.AccessTokenExpires__c = Datetime.now().addHours(1);
			upsert s;

			Test.startTest();
			Credentials.AccessToken result = Credentials.getToken();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('unit.test', result.token);
		}
	}

	@IsTest
	static void test_isAccountValid_valid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Test.startTest();
			System.assert(Credentials.isAccountValid());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_isAccountValid_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			System.assert(!Credentials.isAccountValid());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_insert() {
		UUID accountId = UUID.randomUUID();
		String email = UUID.randomUUID().toString() + '@unit.test';
		UUID userId = UUID.randomUUID();
		User u = UserMock.createDocuSignAdministrator(false);

		System.runAs(u) {
			String token = 'test';
			Datetime expires = Datetime.now().addHours(1);

			Test.startTest();
			Credentials result1 = Credentials.save(
				DocuSign.Environment.Production,
				new Url('https://account.test.docusign.net/'),
				new Url('https://esign.test.docusign.net/'),
				accountId,
				1111L,
				accountId.toString(),
				email,
				userId,
				true,
				new Credentials.AccessToken(token, expires));
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(DocuSign.Environment.Production, result1.environment);
			System.assertNotEquals(null, result1.accountBaseUrl);
			System.assertEquals('https://account.test.docusign.net/', result1.accountBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.eSignatureBaseUrl);
			System.assertEquals('https://esign.test.docusign.net/', result1.eSignatureBaseUrl.toExternalForm());
			System.assertEquals(accountId, result1.accountId);
			System.assertEquals(1111L, result1.accountNumber);
			System.assertEquals(accountId.toString(), result1.accountName);
			System.assertEquals(email, result1.email);
			System.assertEquals(userId, result1.userId);
			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :u.Id LIMIT 1];
			System.assertEquals(userId.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			UserSettings__c s = UserSettings__c.getInstance();
			System.assertEquals(token, s.AccessToken0__c);
			System.assertEquals(expires, s.AccessTokenExpires__c);

			System.assert(result2 === result1);
		}
	}

	@IsTest
	static void test_save_update() {
		UUID accountId = UUID.randomUUID();
		String email = UUID.randomUUID().toString() + '@unit.test';
		UUID userId = UUID.randomUUID();

		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			UserMock.createAccountConfiguration(UUID.randomUUID());
			Credentials baseline = Credentials.getInstance();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.SystemSenderId__c = userId.toString();
			update s;

			Test.startTest();
			Credentials result1 = Credentials.save(
				DocuSign.Environment.Production,
				new Url('https://account1.test.docusign.net/'),
				new Url('https://esign1.test.docusign.net/'),
				accountId,
				2222L,
				accountId.toString(),
				email,
				userId,
				true,
				null);
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assert(result1 !== baseline);
			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(DocuSign.Environment.Production, result1.environment);
			System.assertNotEquals(null, result1.accountBaseUrl);
			System.assertEquals('https://account1.test.docusign.net/', result1.accountBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.eSignatureBaseUrl);
			System.assertEquals('https://esign1.test.docusign.net/', result1.eSignatureBaseUrl.toExternalForm());
			System.assertEquals(accountId, result1.accountId);
			System.assertEquals(2222L, result1.accountNumber);
			System.assertEquals(accountId.toString(), result1.accountName);
			System.assertEquals(email, result1.email);
			System.assertEquals(userId, result1.userId);
			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
			System.assertEquals(userId.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(null, us.AccessToken0__c);
			System.assertEquals(null, us.AccessTokenExpires__c);

			System.assert(result2 === result1);
		}
	}

	@IsTest
	static void test_addUsers() {
		User dsu1 = UserMock.createUser(),
			dsu2 = UserMock.createUser(),
			dsu3 = UserMock.createUser();
		UUID userId1 = UUID.randomUUID(),
			userId2 = UUID.randomUUID();

		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Test.startTest();
			Credentials.addUsers(new Map<Id, Credentials.UserCredentials> {
				dsu1.Id => new Credentials.UserCredentials(userId1, false, null),
				dsu2.Id => new Credentials.UserCredentials(userId2, true, null),
				dsu3.Id => null
			});
			Test.stopTest();

			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu1.Id LIMIT 1];
			System.assertEquals(userId1.toString(), uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignAdministrator(dsu1.Id));
			System.assert(Permissions.isDocuSignUser(dsu1.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu2.Id LIMIT 1];
			System.assertEquals(userId2.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignAdministrator(dsu2.Id));
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu3.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignAdministrator(dsu3.Id));
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	@IsTest
	static void test_clear_account() {
		UUID adminId = UUID.randomUUID(),
			userId1 = UUID.randomUUID(),
			userId2 = UUID.randomUUID(),
			userId3 = UUID.randomUUID();
		User dsa = UserMock.createDocuSignAdministrator(adminId);
		User dsu1 = UserMock.createDocuSignUser(userId1);
		User dsu2 = UserMock.createDocuSignUser(userId2);
		User dsu3 = UserMock.createDocuSignUser(userId3);

		System.runAs(dsa) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId1, result.userId);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId2, result.userId);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId3, result.userId);

			Test.startTest();
			Credentials.clear(false);
			Test.stopTest();

			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Email__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountNumber__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountName__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Features__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().FeaturesLastChecked__c);

			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsa.Id LIMIT 1];
			System.assertEquals(adminId.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu1.Id LIMIT 1];
			System.assertEquals(userId1.toString(), uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignUser(dsu1.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu2.Id LIMIT 1];
			System.assertEquals(userId2.toString(), uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu3.Id LIMIT 1];
			System.assertEquals(userId3.toString(), uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	@IsTest
	static void test_clear_all() {
		UUID adminId = UUID.randomUUID(),
			userId1 = UUID.randomUUID(),
			userId2 = UUID.randomUUID(),
			userId3 = UUID.randomUUID();
		User dsa = UserMock.createDocuSignAdministrator(adminId);
		User dsu1 = UserMock.createDocuSignUser(userId1);
		User dsu2 = UserMock.createDocuSignUser(userId2);
		User dsu3 = UserMock.createDocuSignUser(userId3);

		System.runAs(dsa) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId1, result.userId);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId2, result.userId);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(userId3, result.userId);

			Test.startTest();
			Credentials.clear(true);
			Test.stopTest();

			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Email__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountNumber__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountName__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Features__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().FeaturesLastChecked__c);

			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsa.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu1.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignUser(dsu1.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu2.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignUser(dsu2.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu3.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	@IsTest
	static void test_clear_users() {
		UUID adminId = UUID.randomUUID(),
			userId1 = UUID.randomUUID(),
			userId2 = UUID.randomUUID(),
			userId3 = UUID.randomUUID();
		User dsa = UserMock.createDocuSignAdministrator(adminId);
		User dsu1 = UserMock.createDocuSignUser(userId1);
		User dsu2 = UserMock.createDocuSignUser(userId2);
		User dsu3 = UserMock.createDocuSignUser(userId3);

		System.runAs(dsa) {
			UserMock.createAccountConfiguration(UUID.randomUUID());

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);

			Test.startTest();
			Credentials.clear(new Set<Id> { dsu1.Id, dsu3.Id });
			Test.stopTest();

			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountBaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountNumber__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Email__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountName__c);

			User uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsa.Id LIMIT 1];
			System.assertNotEquals(null, uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu1.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignUser(dsu1.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu2.Id LIMIT 1];
			System.assertNotEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			uu = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :dsu3.Id LIMIT 1];
			System.assertEquals(null, uu.Username__c);
			System.assert(!uu.CanManageAccount__c);
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	@IsTest
	static void test_AccessToken() {
		Credentials.AccessToken tok1 = new Credentials.AccessToken('tok1', Datetime.now().addHours(1));
		Credentials.AccessToken tok2 = new Credentials.AccessToken('tok2', Datetime.now().addHours(-1));
		Credentials.AccessToken tok3 = new Credentials.AccessToken('  ', Datetime.now().addHours(1));

		System.assert(!tok1.isExpired);
		System.assert(tok1.isValid);
		System.assert(tok2.isExpired);
		System.assert(!tok2.isValid);
		System.assert(!tok3.isExpired);
		System.assert(!tok3.isValid);
	}

	@IsTest
	static void test_setToken() {
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = null;
			s.AccessTokenExpires__c = null;
			update s;

			Credentials baseline = Credentials.getInstance();
			System.assertNotEquals(null, baseline);
			System.assertEquals(null, baseline.token);

			String token = UUID.randomUUID().toString();
			Datetime exp = Datetime.now().addHours(1);

			Test.startTest();
			Credentials result = Credentials.setToken(new Credentials.AccessToken(token, exp));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.token);
			System.assertEquals(token, result.token.token);
			System.assertEquals(exp, result.token.expires);
			System.assert(result === baseline);
		}
	}

	@IsTest
	static void test_save_token_valid() {
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = null;
			s.AccessTokenExpires__c = null;
			update s;

			String token = UUID.randomUUID().toString();
			Datetime exp = Datetime.now().addHours(1);
			Credentials baseline = Credentials.setToken(new Credentials.AccessToken(token, exp));
			System.assertNotEquals(null, baseline);
			System.assertNotEquals(null, baseline.token);

			Credentials.UserCredentials uc = Credentials.DB.queryUserCredentials(UserInfo.getUserId());
			System.assertNotEquals(null, uc);
			System.assertEquals(null, uc.token);

			Test.startTest();
			Credentials result1 = Credentials.save();
			Credentials.UserCredentials result2 = Credentials.DB.queryUserCredentials(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 !== baseline);
			System.assertNotEquals(null, result1.token);
			System.assertEquals(token, result1.token.token);
			System.assertEquals(exp, result1.token.expires);

			System.assertNotEquals(null, result2);
			System.assertNotEquals(null, result2.token);
			System.assertEquals(token, result2.token.token);
			System.assertEquals(exp, result2.token.expires);
		}
	}

	@IsTest
	static void test_save_token_invalid() {
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = null;
			s.AccessTokenExpires__c = null;
			update s;

			String token = UUID.randomUUID().toString();
			Datetime exp = Datetime.now().addHours(-1);
			Credentials baseline = Credentials.setToken(new Credentials.AccessToken(token, exp));
			System.assertNotEquals(null, baseline);
			System.assertNotEquals(null, baseline.token);

			Credentials.UserCredentials uc = Credentials.DB.queryUserCredentials(UserInfo.getUserId());
			System.assertNotEquals(null, uc);
			System.assertEquals(null, uc.token);

			Test.startTest();
			Credentials result1 = Credentials.save();
			Credentials.UserCredentials result2 = Credentials.DB.queryUserCredentials(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 !== baseline);
			System.assertNotEquals(null, result1.token);
			System.assertEquals(token, result1.token.token);
			System.assertEquals(exp, result1.token.expires);

			System.assertNotEquals(null, result2);
			System.assertEquals(null, result2.token);
		}
	}

	@IsTest
	static void test_save_token_too_long() {
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = null;
			s.AccessTokenExpires__c = null;
			update s;

			Integer len = Credentials.MAX_TOKEN_LENGTH + 1;
			String token = TestUtils.randomString(len);
			Datetime exp = Datetime.now().addHours(1);
			Credentials baseline = Credentials.setToken(new Credentials.AccessToken(token, exp));
			System.assertNotEquals(null, baseline);
			System.assertNotEquals(null, baseline.token);

			Credentials.UserCredentials uc = Credentials.DB.queryUserCredentials(UserInfo.getUserId());
			System.assertNotEquals(null, uc);
			System.assertEquals(null, uc.token);

			Test.startTest();
			try {
				Credentials.save();
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.AccessTokenTooLong_2, new List<String> {
					String.valueOf(len),
					String.valueOf(Credentials.MAX_TOKEN_LENGTH)
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_new_user() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Credentials result = Credentials.save();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.userId);
			System.assertEquals(null, result.token);
		}
	}
}
