@IsTest
private class PlatformAuthorizationServiceTest {

	@IsTest
	static void test_SalesforceOAuthAPI_getError_exception() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(401);
		// No body so JSON parser throws exception

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertEquals(APIError.unauthorized, result);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getError_generic() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(400);
		response.setStatus('test');
		response.setBody('{}');

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertEquals(APIError.unauthorized, result);
		System.assertEquals('test', result.description);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getError_access_denied() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(400);
		response.setStatus('BAD_REQUEST');
		response.setBody('{"error":"access_denied","error_description":"test"}');

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertEquals(APIError.consentRequired, result);
		System.assertEquals(Label.ConsentRequired, result.description);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getError_inactive_user() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(400);
		response.setStatus('BAD_REQUEST');
		response.setBody('{"error":"inactive_user","error_description":"test"}');

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(APIErrorCode.USER_NOT_ACTIVATED, result.code);
		System.assertEquals('test', result.description);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getError_invalid_app_access() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(400);
		response.setStatus('BAD_REQUEST');
		response.setBody('{"error":"invalid_app_access","error_description":"test"}');

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(APIErrorCode.ADMIN_CONSENT_REQUIRED, result.code);
		System.assertEquals('test', result.description);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getError_invalid_grant() {
		PlatformAuthorizationService.SalesforceOAuthAPI client =
			new PlatformAuthorizationService.SalesforceOAuthAPI();
		HttpResponse response = new HttpResponse();
		response.setStatusCode(400);
		response.setStatus('BAD_REQUEST');
		response.setBody('{"error":"invalid_grant","error_description":"test"}');

		Test.startTest();
		APIError result = client.getError(response);
		Test.stopTest();

		System.assertEquals(APIError.consentRequired, result);
		System.assertEquals(Label.ConsentRequired, result.description);
	}

	@IsTest
	static void test_SalesforceOAuthAPI_generateJwt() {
		System.runAs(UserMock.createDocuSignUser()) {
			PlatformAuthorizationService.SalesforceOAuthAPI client =
				new PlatformAuthorizationService.SalesforceOAuthAPI();
			String clientId = UUID.randomUUID().toString();
			String username = UserInfo.getUserName();
			String audience = 'https://test.salesforce.com';
			Blob jwtSigningKey = TestUtils.TEST_RSA_PRIVATE_KEY;

			Test.startTest();
			System.assert(String.isNotBlank(client.generateJwt(
				clientId,
				username,
				audience,
				jwtSigningKey)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getAccessToken_failure() {
		SalesforceAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			PlatformAuthorizationService.SalesforceOAuthAPI client =
				new PlatformAuthorizationService.SalesforceOAuthAPI();
			String clientId = UUID.randomUUID().toString();
			String username = UserInfo.getUserName();
			String audience = 'https://test.salesforce.com';
			Blob jwtSigningKey = TestUtils.TEST_RSA_PRIVATE_KEY;

			Test.startTest();
			try {
				client.getAccessToken(
					clientId,
					username,
					audience,
					jwtSigningKey);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.CONSENT_REQUIRED, ex.error.code);
				System.assertEquals(Label.ConsentRequired, ex.error.description);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_SalesforceOAuthAPI_getAccessToken_success() {
		SalesforceAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			PlatformAuthorizationService.SalesforceOAuthAPI client =
				new PlatformAuthorizationService.SalesforceOAuthAPI();
			String clientId = UUID.randomUUID().toString();
			String username = UserInfo.getUserName();
			String audience = 'https://test.salesforce.com';
			Blob jwtSigningKey = TestUtils.TEST_RSA_PRIVATE_KEY;

			Test.startTest();
			System.assert(String.isNotBlank(client.getAccessToken(
				clientId,
				username,
				audience,
				jwtSigningKey)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkIsAuthorized_false() {
		SalesforceAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(!PlatformAuthorizationService.checkIsAuthorized());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkIsPlatformAuthorized_true() {
		SalesforceAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(PlatformAuthorizationService.checkIsAuthorized());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAuthStatus_cached() {
		System.runAs(UserMock.createDocuSignUser()) {
			PlatformAuthorizationService.AuthStatus status = new PlatformAuthorizationService.AuthStatus(
				false,
				Datetime.now(),
				15,
				false);

			Test.startTest();
			PlatformAuthorizationService.AuthStatus result = PlatformAuthorizationService.getAuthStatus(status);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(status.isAuthorized, result.isAuthorized);
			System.assertEquals(status.lastChecked, result.lastChecked);
			System.assertEquals(status.checkFrequencyMinutes, result.checkFrequencyMinutes);
			System.assert(!result.isDirty);
		}
	}

	@IsTest
	static void test_getAuthStatus_refreshed() {
		SalesforceAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			PlatformAuthorizationService.AuthStatus status = new PlatformAuthorizationService.AuthStatus(
				true,
				Datetime.now().addMinutes(-16),
				15,
				false);

			Test.startTest();
			PlatformAuthorizationService.AuthStatus result = PlatformAuthorizationService.getAuthStatus(status);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(status.isAuthorized, result.isAuthorized);
			System.assertNotEquals(status.lastChecked, result.lastChecked);
			System.assertEquals(status.checkFrequencyMinutes, result.checkFrequencyMinutes);
			System.assert(result.isDirty);
		}
	}

	@IsTest
	static void test_isAuthorized_unauthorized() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				PlatformAuthorizationService.isAuthorized();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_isAuthorized_authorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(PlatformAuthorizationService.isAuthorized());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_unauthorized() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				PlatformAuthorizationService.save();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_isDirty_false() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			UserSettings__c s1 = UserSettings__c.getInstance();
			s1.IsPlatformAuthorized__c = false;
			s1.PlatformAuthorizationLastChecked__c = Datetime.now().addMinutes(-10);
			s1.PlatformAuthorizationCheckFrequency__c = 15;
			update s1;
			PlatformAuthorizationService.status = new PlatformAuthorizationService.AuthStatus(
				true,
				Datetime.now(),
				15,
				false);

			Test.startTest();
			System.assert(!PlatformAuthorizationService.save());
			Test.stopTest();

			UserSettings__c s2 = UserSettings__c.getInstance();
			System.assertEquals(s1.IsPlatformAuthorized__c, s2.IsPlatformAuthorized__c);
			System.assertEquals(s1.PlatformAuthorizationLastChecked__c, s2.PlatformAuthorizationLastChecked__c);
			System.assertEquals(s1.PlatformAuthorizationCheckFrequency__c, s2.PlatformAuthorizationCheckFrequency__c);
		}
	}

	@IsTest
	static void test_save_isDirty_true() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			UserSettings__c s1 = UserSettings__c.getInstance();
			s1.IsPlatformAuthorized__c = false;
			s1.PlatformAuthorizationLastChecked__c = Datetime.now().addMinutes(-10);
			s1.PlatformAuthorizationCheckFrequency__c = 15;
			update s1;
			PlatformAuthorizationService.status = new PlatformAuthorizationService.AuthStatus(
				true,
				Datetime.now(),
				30,
				true);

			Test.startTest();
			System.assert(PlatformAuthorizationService.save());
			Test.stopTest();

			UserSettings__c s2 = UserSettings__c.getInstance();
			System.assertNotEquals(s1.IsPlatformAuthorized__c, s2.IsPlatformAuthorized__c);
			System.assertNotEquals(s1.PlatformAuthorizationLastChecked__c, s2.PlatformAuthorizationLastChecked__c);
			System.assertNotEquals(s1.PlatformAuthorizationCheckFrequency__c, s2.PlatformAuthorizationCheckFrequency__c);
		}
	}

	@IsTest
	static void test_Database_insertSetupEntityAccess_unauthorized() {
		System.runAs(UserMock.createRestrictedUser()) {
			Test.startTest();
			try {
				PlatformAuthorizationService.DB.insertSetupEntityAccess(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_insertSetupEntityAccess_null() {
		Test.startTest();
		System.assert(Collection.isEmpty(PlatformAuthorizationService.DB.insertSetupEntityAccess(null)));
		Test.stopTest();
	}

	@IsTest
	static void test_Database_insertSetupEntityAccess_partial_success() {
		// Cannot create ConnectedApplication in unit test, so use any available.
		Set<Id> caIds = new Set<Id>();
		for (ConnectedApplication ca : [SELECT Id FROM ConnectedApplication LIMIT 5]) {
			caIds.add(ca.Id);
		}
		Set<Id> psIds = PlatformAuthorizationService.DB.queryPermissionSetIds();

		// pre-authorize to trigger insert failure
		if (Collection.isNotEmpty(caIds) && Collection.isNotEmpty(psIds)) {
			PlatformAuthorizationService.DB.insertSetupEntityAccess(new List<SetupEntityAccess> {
				new SetupEntityAccess(
					ParentId = (Id)Collection.head(psIds),
					SetupEntityId = (Id)Collection.head(caIds))
			});

			List<SetupEntityAccess> seas = new List<SetupEntityAccess>();
			for (Id psId : psIds) {
				for (Id caId : caIds) {
					seas.add(new SetupEntityAccess(
						ParentId = psId,
						SetupEntityId = caId));
				}
			}

			Test.startTest();
			System.assertEquals(
				psIds.size() * caIds.size(),
				Collection.size(PlatformAuthorizationService.DB.insertSetupEntityAccess(seas)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_deleteSetupEntityAccess_unauthorized() {
		System.runAs(UserMock.createRestrictedUser()) {
			Test.startTest();
			try {
				PlatformAuthorizationService.DB.deleteSetupEntityAccess(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_deleteSetupEntityAccess_null() {
		Test.startTest();
		System.assert(Collection.isEmpty(PlatformAuthorizationService.DB.deleteSetupEntityAccess(null)));
		Test.stopTest();
	}

	@IsTest
	static void test_authorize_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				PlatformAuthorizationService.authorize();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	// Fails with an ISE sometimes
//	@IsTest
//	static void test_authorize_success() {
//		System.runAs(UserMock.createDocuSignAdministrator(false)) {
//			Test.startTest();
//			System.assertNotEquals(null, PlatformAuthorizationService.authorize());
//			Test.stopTest();
//		}
//	}

	@IsTest
	static void test_deauthorize_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				PlatformAuthorizationService.deauthorize();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	// This fails with an ISE when run with all tests. When run by itself it succeeds.
//	@IsTest
//	static void test_deauthorize_success() {
//		System.runAs(UserMock.createDocuSignAdministrator(false)) {
//			Test.startTest();
//			System.assertNotEquals(null, PlatformAuthorizationService.deauthorize());
//			Test.stopTest();
//		}
//	}
}
