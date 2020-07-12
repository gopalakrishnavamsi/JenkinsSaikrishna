@IsTest
private class AuthControllerTest {

	@IsTest
	static void test_getAuthStatus_unauthorized() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(Label.MustBeDocuSignUser, result.message);
		}
	}

	@IsTest
	static void test_getAuthStatus_account_not_configured() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(Label.AccountNotConfigured, result.message);
		}
	}

	@IsTest
	static void test_getAuthStatus_may_require_activation() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.SystemSenderId__c = null;
			update s;

			delete UserSettings__c.getInstance();

			User u = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
			u.Username__c = null;
			update u;

			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(Label.MustBeActivated, result.message);
		}
	}

	class ConsentRequiredMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"error":"consent_required","error_message":"Consent is required."}');
			return response;
		}
	}

	@IsTest
	static void test_getAuthStatus_consent_required() {
		Test.setMock(HttpCalloutMock.class, new ConsentRequiredMock());
		System.runAs(UserMock.createDocuSignUser()) {
			delete UserSettings__c.getInstance();

			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(result.isConsentRequired);
			System.assertEquals(Label.ConsentRequired, result.message);
		}
	}

	class ApiErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"error":"api_error","error_message":"API error."}');
			return response;
		}
	}

	@IsTest
	static void test_getAuthStatus_api_error() {
		Test.setMock(HttpCalloutMock.class, new ApiErrorMock());
		System.runAs(UserMock.createDocuSignUser()) {
			delete UserSettings__c.getInstance();

			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals('API error.', result.message);
		}
	}

	@IsTest
	static void test_getAuthStatus_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(null, result.message);
			System.assertEquals(4, result.products.size());
		}
	}

	@IsTest
	static void test_getAuthStatusWithPermissions_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Permissions.assignPermissionSets(
				new Set<Id> { UserInfo.getUserId() },
				new Set<String> { Permissions.DOCUSIGN_GENERATOR, Permissions.DOCUSIGN_NEGOTIATOR });

			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(null, result.message);
			System.assertEquals(4, result.products.size());
			System.assertEquals(true, result.permission.isDocuSignAdministrator);
			System.assertEquals(true, result.permission.isDocuSignIntegrationUser);
			System.assertEquals(true, result.permission.isDocuSignGenerator);
			System.assertEquals(true, result.permission.isDocuSignNegotiator);
		}
	}

	@IsTest
	static void test_getAuthStatus_salesforce_error() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Account not configured
			Test.startTest();
			AuthController.AuthStatus result = AuthController.getAuthStatus();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isAuthorized);
			System.assert(!result.isConsentRequired);
			System.assertEquals(Label.AccountNotConfigured, result.message);
		}
	}

	@IsTest
	static void test_beginOAuth_failure() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				AuthController.beginOAuth(TestUtils.getOrigin());
				throw new AssertException('Expected beginOAuth to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String result = AuthController.beginOAuth(TestUtils.getOrigin());
			Test.stopTest();

			System.assert(String.isNotBlank(result));
			System.assert(!result.contains('+'));
		}
	}

	@IsTest
	static void test_getConfigAfterAuthorization() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Permissions.assignPermissionSets(
				new Set<Id> { UserInfo.getUserId() },
				new Set<String> { Permissions.DOCUSIGN_GENERATOR, Permissions.DOCUSIGN_NEGOTIATOR });

			Test.startTest();
			AuthController.AuthStatus config = AuthController.getConfigAfterAuthorization();
			System.assertNotEquals(config, null);
			Test.stopTest();

			System.assertEquals(4, config.products.size());
			System.assertEquals(true, config.permission.isDocuSignAdministrator);
			System.assertEquals(true, config.permission.isDocuSignIntegrationUser);
			System.assertEquals(true, config.permission.isDocuSignGenerator);
			System.assertEquals(true, config.permission.isDocuSignNegotiator);
		}
	}

	@IsTest
	static void test_completeDocuSignOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AuthController.completeDocuSignOAuth(
					'code',
					TestUtils.generateDocuSignOAuthState(true),
					null,
					null);
				throw new AssertException('Expected completeDocuSignOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeDocuSignOAuth_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateDocuSignOAuthState(true);

			Test.startTest();
			LoginInformation result = AuthController.completeDocuSignOAuth(
				'code',
				state,
				null,
				null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_SUCCESS, result.status);
		}
	}

	@IsTest
	static void test_completeDocuSignOAuth_error() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateDocuSignOAuthState(true);

			Test.startTest();
			LoginInformation result = AuthController.completeDocuSignOAuth(
				null,
				state,
				'consent_required',
				'Consent required.');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_FAILURE, result.status);
			System.assertEquals(Label.ConsentRequired, result.message);
		}
	}

	@IsTest
	static void test_getConfigAfterAuthorizationFailure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AuthController.getConfigAfterAuthorization();
				throw new AssertException('Expected getConfigAfterAuthorization to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_processProductCheckInAccountSetting() {
		System.runAs(UserMock.createDocuSignUser(true)) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.IsESignatureEnabled__c = false;
			update s;

			Test.startTest();
			AuthController.AuthStatus config = AuthController.getConfigAfterAuthorization();
			Test.stopTest();

			System.assertEquals(3, config.products.size());
		}
	}

	@IsTest
	static void test_beginSalesforceOAuth_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String result = AuthController.beginSalesforceOAuth(
				LoginInformation.TYPE_USER,
				TestUtils.getOrigin());
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_completeSalesforceOAuth_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String state = TestUtils.generateSalesforceOAuthState(true);

			Test.startTest();
			LoginInformation result = AuthController.completeSalesforceOAuth(
				'unit.test',
				state,
				null,
				null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_SUCCESS, result.status);
			System.assertEquals(Label.SuccessDocuSignAuthorization, result.message);
		}
	}

	@IsTest
	static void test_completeSalesforceOAuth_error() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String state = TestUtils.generateSalesforceOAuthState(true);

			Test.startTest();
			LoginInformation result = AuthController.completeSalesforceOAuth(
				'unit.test',
				state,
				'access_denied',
				'enduser denied authorization');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_FAILURE, result.status);
			System.assertEquals(Label.ConsentRequired, result.message);
		}
	}
}
