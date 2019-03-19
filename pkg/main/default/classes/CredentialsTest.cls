@IsTest
private class CredentialsTest {

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
			UUID ssId = UUID.tryParse(AccountSettings__c.getOrgDefaults().SystemSenderId__c);
			System.assertNotEquals(null, ssId);

			Test.startTest();
			Credentials result1 = Credentials.getInstance(u1.Id, true);
			Credentials result2 = Credentials.getInstance(u2.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertNotEquals(null, result1.user);
			System.assertEquals(ssId, result1.user.id);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
			System.assertNotEquals(null, result2.user);
			System.assertEquals(ssId, result2.user.id);
		}
	}

	@IsTest
	static void test_getToken() {
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = 'unit.';
			s.AccessToken1__c = 'test.';
			s.AccessToken2__c = 'token';
			s.AccessTokenExpires__c = Datetime.now().addHours(1);
			upsert s;

			Credentials c = Credentials.getInstance();
			System.assertNotEquals(null, c);
			System.assertNotEquals(null, c.token);
			System.assert(c.token.isValid);

			Test.startTest();
			Credentials.AccessToken result = Credentials.getToken();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('unit.test.token', result.token);
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
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String token = 'test';
			Datetime expires = Datetime.now().addHours(1);
			String clientId = UUID.randomUUID().toString();
			String clientSecret = UUID.randomUUID().toString();
			String pvk = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			Credentials result1 = Credentials.save(
				new Credentials.Environment(
					DocuSign.Environment.Production,
					new Url('https://account.test.docusign.net/'),
					new Url('https://api.test.docusign.net/'),
					new Url('https://esign.test.docusign.net/'),
					new Url('https://auth.test.springcm.com/'),
					new Url('https://api.test.springcm.com/')),
				new Credentials.ClientCredentials(
					clientId,
					clientSecret,
					EncodingUtil.base64Decode(pvk)),
				new Credentials.AccountCredentials(
					accountId,
					1111L,
					accountId.toString(),
					email,
					null),
				new Credentials.UserCredentials(
					userId,
					userId.toString(),
					email,
					true),
				new Credentials.AccessToken(token, expires));
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);

			System.assertNotEquals(null, result1.environment);
			System.assertEquals(DocuSign.Environment.Production, result1.environment.environment);
			System.assertNotEquals(null, result1.environment.accountBaseUrl);
			System.assertEquals('https://account.test.docusign.net/', result1.environment.accountBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.provisioningBaseUrl);
			System.assertEquals('https://api.test.docusign.net/', result1.environment.provisioningBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.eSignatureBaseUrl);
			System.assertEquals('https://esign.test.docusign.net/', result1.environment.eSignatureBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.scmAuthBaseUrl);
			System.assertEquals('https://auth.test.springcm.com/', result1.environment.scmAuthBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.scmApiBaseUrl);
			System.assertEquals('https://api.test.springcm.com/', result1.environment.scmApiBaseUrl.toExternalForm());

			System.assertNotEquals(null, result1.client);
			System.assertEquals(clientId, result1.client.id);
			System.assertEquals(clientSecret, result1.client.secret);
			System.assertEquals(pvk, EncodingUtil.base64Encode(result1.client.privateKey));

			System.assertNotEquals(null, result1.account);
			System.assertEquals(accountId, result1.account.id);
			System.assertEquals(1111L, result1.account.accountNumber);
			System.assertEquals(accountId.toString(), result1.account.name);
			System.assertEquals(email, result1.account.email);
			System.assertEquals(null, result1.account.systemSenderId);

			System.assertNotEquals(null, result1.user);
			System.assertEquals(userId, result1.user.id);
			User uu = [SELECT Name, Email, Username__c, CanManageAccount__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
			System.assertEquals(userId.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			System.assertEquals(uu.Name, result1.user.name);
			System.assertEquals(uu.Email, result1.user.email);
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
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			UserMock.createAccountConfiguration(UUID.randomUUID());
			Credentials baseline = Credentials.getInstance();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.SystemSenderId__c = userId.toString();
			update s;
			String token = 'test';
			Datetime expires = Datetime.now().addHours(1);
			String clientId = UUID.randomUUID().toString();
			String clientSecret = UUID.randomUUID().toString();
			String pvk = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			Credentials result1 = Credentials.save(
				new Credentials.Environment(
					DocuSign.Environment.Production,
					new Url('https://account1.test.docusign.net/'),
					new Url('https://api1.test.docusign.net/'),
					new Url('https://esign1.test.docusign.net/'),
					new Url('https://auth1.test.springcm.com/'),
					new Url('https://api1.test.springcm.com/')),
				new Credentials.ClientCredentials(
					clientId,
					clientSecret,
					EncodingUtil.base64Decode(pvk)),
				new Credentials.AccountCredentials(
					accountId,
					2222L,
					accountId.toString(),
					email,
					null),
				new Credentials.UserCredentials(
					userId,
					userId.toString(),
					email,
					true),
				new Credentials.AccessToken(token, expires));
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assert(result1 !== baseline);

			System.assertNotEquals(null, result1.environment);
			System.assertEquals(DocuSign.Environment.Production, result1.environment.environment);
			System.assertNotEquals(null, result1.environment.accountBaseUrl);
			System.assertEquals('https://account1.test.docusign.net/', result1.environment.accountBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.provisioningBaseUrl);
			System.assertEquals('https://api1.test.docusign.net/', result1.environment.provisioningBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.eSignatureBaseUrl);
			System.assertEquals('https://esign1.test.docusign.net/', result1.environment.eSignatureBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.scmAuthBaseUrl);
			System.assertEquals('https://auth1.test.springcm.com/', result1.environment.scmAuthBaseUrl.toExternalForm());
			System.assertNotEquals(null, result1.environment.scmApiBaseUrl);
			System.assertEquals('https://api1.test.springcm.com/', result1.environment.scmApiBaseUrl.toExternalForm());

			System.assertNotEquals(null, result1.client);
			System.assertEquals(clientId, result1.client.id);
			System.assertEquals(clientSecret, result1.client.secret);
			System.assertEquals(pvk, EncodingUtil.base64Encode(result1.client.privateKey));

			System.assertNotEquals(null, result1.account);
			System.assertEquals(accountId, result1.account.id);
			System.assertEquals(2222L, result1.account.accountNumber);
			System.assertEquals(accountId.toString(), result1.account.name);
			System.assertEquals(email, result1.account.email);
			System.assertEquals(null, result1.account.systemSenderId);

			System.assertNotEquals(null, result1.user);
			System.assertEquals(userId, result1.user.id);
			User uu = [SELECT Name, Email, Username__c, CanManageAccount__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
			System.assertEquals(userId.toString(), uu.Username__c);
			System.assert(uu.CanManageAccount__c);
			System.assertEquals(uu.Name, result1.user.name);
			System.assertEquals(uu.Email, result1.user.email);

			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(token, us.AccessToken0__c);
			System.assertEquals(expires, us.AccessTokenExpires__c);

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
			Map<Id, Credentials.UserCredentials> result = Credentials.addUsers(new Map<Id, Credentials.UserCredentials> {
				dsu1.Id => new Credentials.UserCredentials(userId1, 'u1', 'u1@unit.test', false),
				dsu2.Id => new Credentials.UserCredentials(userId2, 'u2', 'u2@unit.test', true),
				dsu3.Id => null
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

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
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId1, result.user.id);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId2, result.user.id);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId3, result.user.id);

			Test.startTest();
			Credentials.clear(false);
			Test.stopTest();

			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ProvisioningBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ScmAuthBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ScmApiBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().InviteCallbackUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().InviteRedirectUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Email__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountNumber__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountName__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Features__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().FeaturesLastChecked__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AdministratorProfileId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().SenderProfileId__c);

			System.assert(Collection.isEmpty([SELECT Id FROM Configuration__c WHERE Name = 'Gen' LIMIT 1]));

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
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId1, result.user.id);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId2, result.user.id);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.user);
			System.assertEquals(userId3, result.user.id);

			Test.startTest();
			Credentials.clear(true);
			Test.stopTest();

			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ProvisioningBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ScmAuthBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ScmApiBaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().InviteCallbackUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().InviteRedirectUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Email__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountNumber__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountName__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Features__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().FeaturesLastChecked__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AdministratorProfileId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().SenderProfileId__c);

			System.assert(Collection.isEmpty([SELECT Id FROM Configuration__c WHERE Name = 'Gen' LIMIT 1]));

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
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ProvisioningBaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ESignatureBaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ScmAuthBaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ScmApiBaseUrl__c);
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

		System.assert(tok1.isValid);
		System.assert(!tok2.isValid);
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
			System.assert(!baseline.isTokenValid);

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

			Credentials.AccessToken uc = Credentials.DB.getToken(UserSettings__c.getInstance(UserInfo.getUserId()));
			System.assertNotEquals(null, uc);
			System.assert(!uc.isValid);

			Test.startTest();
			Credentials result1 = Credentials.save();
			Credentials.AccessToken result2 = Credentials.DB.getToken(UserSettings__c.getInstance(UserInfo.getUserId()));
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.token);
			System.assertEquals(token, result1.token.token);
			System.assertEquals(exp, result1.token.expires);

			System.assertNotEquals(null, result2);
			System.assertEquals(token, result2.token);
			System.assertEquals(exp, result2.expires);
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

			Credentials.AccessToken uc = Credentials.DB.queryToken(UserInfo.getUserId());
			System.assertNotEquals(null, uc);
			System.assertEquals(null, uc.token);

			Test.startTest();
			Credentials result1 = Credentials.save();
			Credentials.AccessToken result2 = Credentials.DB.queryToken(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.token);
			System.assertEquals(token, result1.token.token);
			System.assertEquals(exp, result1.token.expires);

			System.assertNotEquals(null, result2);
			System.assertEquals(null, result2.token);
			System.assertEquals(null, result2.expires);
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

			Credentials.AccessToken uc = Credentials.DB.queryToken(UserInfo.getUserId());
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
	static void test_save_private_key_too_long() {
		System.runAs(UserMock.createDocuSignUser()) {
			Credentials baseline = Credentials.getInstance();
			System.assertNotEquals(null, baseline);
			System.assertNotEquals(null, baseline.client);
			System.assertNotEquals(null, baseline.client.privateKey);
			Blob pvk = Blob.valueOf(TestUtils.randomString(Credentials.MAX_KEY_LENGTH + 1));
			Integer len = EncodingUtil.base64Encode(pvk).length();

			Test.startTest();
			try {
				Credentials.save(
					baseline.environment,
					new Credentials.ClientCredentials(
						baseline.client.id,
						baseline.client.secret,
						pvk),
					baseline.account,
					baseline.user,
					baseline.token);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.KeyTooLong_2, new List<String> {
					String.valueOf(len),
					String.valueOf(Credentials.MAX_KEY_LENGTH)
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}
}