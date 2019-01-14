@IsTest
private class SetupControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			SetupController result = new SetupController();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.lightningNamespace, result.namespace);
			System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
			System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
		}
	}

	@IsTest
	static void test_getLogin_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			LoginInformation result = SetupController.getLogin();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			Credentials c = Credentials.getInstance();
			System.assertEquals(c.userId, result.id);
			System.assertEquals(null, result.name);
			System.assertEquals(c.email, result.email);
			System.assertEquals(1, Collection.size(result.accounts));
			System.assertEquals(c.accountId, result.accounts[0].id);
			System.assertEquals(c.accountNumber, result.accounts[0].accountNumber);
			System.assertEquals(c.accountName, result.accounts[0].name);
			System.assertEquals(c.eSignatureBaseUrl.toExternalForm(), result.accounts[0].baseUrl);
			System.assert(result.accounts[0].isDefault);
		}
	}

	@IsTest
	static void test_getLogin_no_account() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			LoginInformation result = SetupController.getLogin();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Failure', result.status);
			System.assertEquals(null, result.id);
			System.assertEquals(UserInfo.getName(), result.name);
			System.assertEquals(UserInfo.getUserEmail(), result.email);
			System.assertEquals(0, Collection.size(result.accounts));
		}
	}

	@IsTest
	static void test_getLogin_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getLogin();
				throw new AssertException('Expected getLogin to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.beginOAuth('prod', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_failure() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				SetupController.beginOAuth(null, null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth('', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth('  ', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth('other', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth('other', 'https://example.com');
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			TestUtils.generateKey();

			Test.startTest();
			System.assertNotEquals(null, SetupController.beginOAuth('PROD', null));
			System.assertNotEquals(null, SetupController.beginOAuth('pRODUCTIOn', null));
			System.assertNotEquals(null, SetupController.beginOAuth('demo', null));
			System.assertNotEquals(null, SetupController.beginOAuth('stage', null));
			System.assertNotEquals(null, SetupController.beginOAuth('other', 'https://other.docusign.com'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.completeOAuth('code', 'state');
				throw new AssertException('Expected completeOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeOAuth_success() {
		ESignatureAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState();

			Test.startTest();
			LoginInformation result = SetupController.completeOAuth('code', state);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.Success.name(), result.status);
		}
	}

	@IsTest
	static void test_selectAccount_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.selectAccount(null, null, UUID.randomUUID().toString(), null);
				throw new AssertException('Expected selectAccount to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_success() {
		ESignatureAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String userId = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			Long accountNumber = (Long)AccountSettings__c.getOrgDefaults().AccountNumber__c;

			Test.startTest();
			LoginInformation result = SetupController.selectAccount('prod', null, userId, accountNumber);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.Success.name(), result.status);
		}
	}

	@IsTest
	static void test_getAccount_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Account result = SetupController.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getAccount_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_logout_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			LoginInformation result = SetupController.logout(true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.id);
			System.assertEquals(UserInfo.getName(), result.name);
			System.assertEquals(UserInfo.getUserEmail(), result.email);
			System.assertEquals(0, Collection.size(result.accounts));

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.Environment__c);
			System.assertEquals(null, s.AccountBaseUrl__c);
			System.assertEquals(null, s.ESignatureBaseUrl__c);
			System.assertEquals(null, s.AccountId__c);
			System.assertEquals(null, s.AccountNumber__c);
			System.assertEquals(null, s.AccountName__c);
			System.assertEquals(null, s.Email__c);

			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c);
			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(null, us.AccessToken0__c);
			System.assertEquals(null, us.AccessToken1__c);
			System.assertEquals(null, us.AccessToken2__c);
			System.assertEquals(null, us.AccessToken3__c);
			System.assertEquals(null, us.AccessToken4__c);
			System.assertEquals(null, us.AccessToken5__c);
			System.assertEquals(null, us.AccessTokenExpires__c);
		}
	}

	@IsTest
	static void test_logout_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.logout(false);
				throw new AssertException('Expected logout to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addUser_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createUser();

			Test.startTest();
			List<Account.User> result = SetupController.addUser(u.Id, u.Email, u.FirstName, u.LastName, false);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_addUser_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.addUser(null, null, null, null, false);
				throw new AssertException('Expected addUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class UserFailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			response.setBody('{"newUsers": [{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails":{"errorCode":"MAX_MEMBERS_EXCEEDED","message":"The maximum number of members for the account has been exceeded."}}]}');

			return response;
		}
	}

	@IsTest
	static void test_addUser_api_failure() {
		Test.setMock(HttpCalloutMock.class, new UserFailureMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createUser();
			ESignatureAPI.Error e = new ESignatureAPI.Error(400, 'MAX_MEMBERS_EXCEEDED', 'The maximum number of members for the account has been exceeded.');

			Test.startTest();
			try {
				SetupController.addUser(u.Id, u.Email, u.FirstName, u.LastName, false);
				throw new AssertException('Expected addUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(String.format('[{0}] {1}', new List<String> { e.docuSignCode, e.description }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeUser_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createDocuSignUser(false);

			Test.startTest();
			List<Account.User> result = SetupController.removeUser(u.Id, u.Username__c);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_removeUser_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.removeUser(null, null);
				throw new AssertException('Expected removeUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Account.User> result = SetupController.getUsers();
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_getUsers_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getUsers();
				throw new AssertException('Expected getUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUser_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			User result = SetupController.getUser(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getUser_failure() {
		System.runAs(UserMock.createRestrictedUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getUser(null);
				throw new AssertException('Expected getUser to fail');
			} catch (AuraHandledException ex) {
				System.assert(String.isNotBlank(ex.getMessage()));
			}
			Test.stopTest();
		}
	}
}
