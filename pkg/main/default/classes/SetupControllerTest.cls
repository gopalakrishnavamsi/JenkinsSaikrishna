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
	static void test_getTarget() {
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget(null));
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget(''));
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget('  '));
		System.assertEquals(Environment.Target.Production, SetupController.getTarget('PROD'));
		System.assertEquals(Environment.Target.Production, SetupController.getTarget('production'));
		System.assertEquals(Environment.Target.Demo, SetupController.getTarget('demo'));
		System.assertEquals(Environment.Target.Stage, SetupController.getTarget('stage'));
		System.assertEquals(Environment.Target.Other, SetupController.getTarget('whatever'));
	}

	@IsTest
	static void test_getLogin_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			SetupController.LoginInformation result = SetupController.getLogin();
			Test.stopTest();

			System.assertNotEquals(null, result);
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

	private class InvalidUsernamePasswordMock implements HttpCalloutMock {

		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(401);
			response.setStatus('UNAUTHORIZED');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"errorCode": "USER_AUTHENTICATION_FAILED","message": "One or both of Username and Password are invalid."}');
			return response;
		}
	}

	@IsTest
	static void test_login_invalid_username_password() {
		Test.setMock(HttpCalloutMock.class, new InvalidUsernamePasswordMock());

		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				SetupController.login('u', 'p', 'demo', null, null);
				throw new AssertException('Expected login to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.InvalidUsernameOrPassword, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_login_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			SetupController.LoginInformation result = SetupController.login('u', 'p', 'demo', null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success.name(), result.status);
		}
	}

	@IsTest
	static void test_login_multiple_accounts() {
		Test.setMock(HttpCalloutMock.class, new AccountServiceTest.MultipleAccountMock());

		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			SetupController.LoginInformation result = SetupController.login('u', 'p', 'other',
				'https://unit.test.docusign.net', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('u', result.email);
			System.assertEquals('other', result.environment);
			System.assertEquals('https://unit.test.docusign.net', result.otherUrl);
			System.assertEquals(AccountService.LoginStatus.SelectAccount.name(), result.status);
			System.assert(Collection.isNotEmpty(result.accountOptions));
		}
	}

	@IsTest
	static void test_login_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.login('u', 'p', 'demo', null, null);
				throw new AssertException('Expected login to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Account result = SetupController.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getAccount_failure() {
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
			SetupController.logout(true);
			Test.stopTest();

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.Username__c);
			System.assertEquals(null, s.Password__c);
			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(null, us.Username__c);
			System.assertEquals(null, us.Password__c);
		}
	}

	@IsTest
	static void test_logout_failure() {
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
	static void test_prepareTrial_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.TrialAccount result = SetupController.prepareTrial('u@unit.test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_prepareTrial_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.prepareTrial(null);
				throw new AssertException('Expected prepareTrial to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrial_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Account.Trial t = new Account.Trial('UNIT TEST', new Account.TrialUser(
				'u@unit.test', 'UNIT', 'TEST', 'US', true
			), null);

			Test.startTest();
			Account.Membership result = SetupController.startTrial(JSON.serialize(t));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_startTrial_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.startTrial('{}');
				throw new AssertException('Expected startTrial to fail');
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
			DocuSignAPI.Error e = new DocuSignAPI.Error(400, 'MAX_MEMBERS_EXCEEDED', 'The maximum number of members for the account has been exceeded.');

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
