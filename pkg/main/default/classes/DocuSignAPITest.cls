@IsTest
private class DocuSignAPITest {

	@IsTest
	static void test_ErrorDetails() {
		DocuSignAPI.ErrorDetails ed1 = new DocuSignAPI.ErrorDetails();
		ed1.errorCode = 'SUCCESS';
		ed1.message = 'No error';
		DocuSignAPI.ErrorDetails ed2 = new DocuSignAPI.ErrorDetails();
		ed2.errorCode = 'INVALID_PASSWORD';
		ed2.message = 'Invalid password';
		DocuSignAPI.ErrorDetails ed3 = new DocuSignAPI.ErrorDetails();
		ed3.errorCode = 'AUTHORIZATION_INVALID_TOKEN';
		ed3.message = 'Authorization invalid token';
		DocuSignAPI.ErrorDetails ed4 = new DocuSignAPI.ErrorDetails();
		ed4.errorCode = 'USER_AUTHENTICATION_FAILED';
		ed4.message = 'User authentication failed';
		DocuSignAPI.ErrorDetails ed5 = new DocuSignAPI.ErrorDetails();
		ed5.errorCode = 'SOME_ERROR';
		ed5.message = 'Some error';

		Test.startTest();
		APIError e1 = ed1.toExternalForm();
		APIError e2 = ed2.toExternalForm();
		APIError e3 = ed3.toExternalForm();
		APIError e4 = ed4.toExternalForm();
		APIError e5 = ed5.toExternalForm();
		Test.stopTest();

		System.assertEquals(APIError.none, e1);

		System.assertNotEquals(null, e2);
		System.assert(e2 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e2.code);
		System.assertEquals('Invalid password', e2.description);
		System.assertEquals('INVALID_PASSWORD', ((DocuSignAPI.Error)e2).docuSignCode);

		System.assertNotEquals(null, e3);
		System.assert(e3 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e3.code);
		System.assertEquals('Authorization invalid token', e3.description);
		System.assertEquals('AUTHORIZATION_INVALID_TOKEN', ((DocuSignAPI.Error)e3).docuSignCode);

		System.assertNotEquals(null, e4);
		System.assert(e4 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e4.code);
		System.assertEquals('User authentication failed', e4.description);
		System.assertEquals('USER_AUTHENTICATION_FAILED', ((DocuSignAPI.Error)e4).docuSignCode);

		System.assertNotEquals(null, e5);
		System.assert(e5 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.BAD_REQUEST, e5.code);
		System.assertEquals('Some error', e5.description);
		System.assertEquals('SOME_ERROR', ((DocuSignAPI.Error)e5).docuSignCode);
	}

	@IsTest
	static void test_constructor_default_creds() {
		UserMock.createDocuSignAdministrator();

		System.runAs(UserMock.createDocuSignUser(false)) {
			Credentials credentials = Credentials.getInstance();
			System.assertNotEquals(null, credentials);
			System.assert(credentials.isValid);

			Test.startTest();
			DocuSignAPI c = DocuSignAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, c);
			DocuSignAPI.LegacyCredentials lc = (DocuSignAPI.LegacyCredentials)JSON.deserialize(c.legacyAuthHeader,
				DocuSignAPI.LegacyCredentials.class);
			System.assertEquals(credentials.username, lc.Username);
			System.assertEquals(credentials.password, lc.Password);
			System.assertEquals(Application.INTEGRATOR_KEY, lc.IntegratorKey);
			System.assertEquals(credentials.sendOnBehalfOf, lc.SendOnBehalfOf);
			System.assertEquals(new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'X-DocuSign-Authentication' => c.legacyAuthHeader
			}, c.defaultHeaders);
			System.assertNotEquals(null, c.baseUrl);
			System.assertNotEquals(null, c.environment);
			System.assertEquals(Environment.Target.Other, c.environment.environment);
			System.assertEquals(credentials.environment.baseUrl.toExternalForm(), c.baseUrl.toExternalForm());
			System.assertEquals(Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c), RestAPI.defaultTimeout);
		}
	}

	@IsTest
	static void test_constructor_non_default_creds() {
		UserMock.createDocuSignAdministrator();
		final Credentials creds = new Credentials(
			Environment.demo,
			UUID.randomUUID(),
			1234L,
			UUID.randomUUID().toString() + '@unit.test',
			UUID.randomUUID().toString(),
			UUID.randomUUID().toString(),
			true,
			UUID.randomUUID().toString(),
			true);

		Test.startTest();
		final DocuSignAPI c = new DocuSignAPI(creds);
		Test.stopTest();

		System.assertNotEquals(null, c);
		DocuSignAPI.LegacyCredentials lc = (DocuSignAPI.LegacyCredentials)JSON.deserialize(c.legacyAuthHeader, DocuSignAPI.LegacyCredentials.class);
		System.assertEquals(creds.username, lc.Username);
		System.assertEquals(creds.password, lc.Password);
		System.assertEquals(Application.INTEGRATOR_KEY, lc.IntegratorKey);
		System.assertEquals(creds.sendOnBehalfOf, lc.SendOnBehalfOf);
		System.assertEquals(new Map<String, String> {
			'Content-Type' => 'application/json',
			'Accept' => 'application/json',
			'X-DocuSign-Authentication' => c.legacyAuthHeader
		}, c.defaultHeaders);
		System.assertNotEquals(null, c.baseUrl);
		System.assertEquals(
			creds.environment.baseUrl.toExternalForm(),
			c.baseUrl.toExternalForm());
		System.assertEquals(Environment.Target.Demo, c.environment.environment);
		System.assertEquals(
			Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c),
			RestAPI.defaultTimeout);
	}

	@IsTest
	static void test_constructor_failure() {
		Test.startTest();
		try {
			new DocuSignAPI(Credentials.getInstance(null, null, null));
			throw new AssertException('Expected DocuSignAPI constructor to throw exception when an account is not configured');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getBaseUrl_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID accountID = UUID.parse(AccountSettings__c.getOrgDefaults().AccountId__c);
			DocuSignAPI client = DocuSignAPI.getInstance();

			Test.startTest();
			Url u = client.getBaseUrl();
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals(client.baseUrl.toExternalForm() + 'restapi/v2/accounts/' + accountID + '/', u.toExternalForm());
		}
	}

	@IsTest
	static void test_getBaseUrl_failure() {
		Test.startTest();
		try {
			new DocuSignAPI(new Credentials(Environment.production, null, null, null, null, null, false, null, false))
				.getBaseUrl();
			throw new AssertException('Expected getBaseUrl to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getError_exception() {
		System.runAs(UserMock.createDocuSignUser()) {
			DocuSignAPI client = DocuSignAPI.getInstance();
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			Test.startTest();
			APIError error = client.getError(response);
			Test.stopTest();

			System.assertNotEquals(null, error);
			System.assertEquals(400, error.code);
			System.assertEquals('BAD_REQUEST', error.description);
		}
	}

	@IsTest
	static void test_getError_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			DocuSignAPI client = DocuSignAPI.getInstance();
			HttpResponse response = new HttpResponse();
			response.setStatusCode(401);
			response.setStatus('UNAUTHORIZED');
			UnauthorizedException ex;

			Test.startTest();
			try {
				client.getError(response);
				throw new AssertException('Expected getError to throw UnauthorizedException');
			} catch (UnauthorizedException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(Label.MustBeActivated, ex.getMessage());
			System.assertEquals(UserInfo.getUserId(), ex.userId);
			System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignUser, ex.requirement);
		}
	}

	@IsTest
	static void test_ping_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(DocuSignAPI.getInstance().ping());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_ping_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(!DocuSignAPI.getInstance().ping());
			Test.stopTest();
		}
	}
}