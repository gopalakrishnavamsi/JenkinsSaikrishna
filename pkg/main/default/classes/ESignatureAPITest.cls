@IsTest
private class ESignatureAPITest {

	@IsTest
	static void test_ErrorDetails() {
		ESignatureAPI.ErrorDetails ed1 = new ESignatureAPI.ErrorDetails();
		ed1.errorCode = 'SUCCESS';
		ed1.message = 'No error';
		ESignatureAPI.ErrorDetails ed2 = new ESignatureAPI.ErrorDetails();
		ed2.errorCode = 'INVALID_PASSWORD';
		ed2.message = 'Invalid password';
		ESignatureAPI.ErrorDetails ed3 = new ESignatureAPI.ErrorDetails();
		ed3.errorCode = 'AUTHORIZATION_INVALID_TOKEN';
		ed3.message = 'Authorization invalid token';
		ESignatureAPI.ErrorDetails ed4 = new ESignatureAPI.ErrorDetails();
		ed4.errorCode = 'USER_AUTHENTICATION_FAILED';
		ed4.message = 'User authentication failed';
		ESignatureAPI.ErrorDetails ed5 = new ESignatureAPI.ErrorDetails();
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
		System.assert(e2 instanceof ESignatureAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e2.code);
		System.assertEquals('Invalid password', e2.description);
		System.assertEquals('INVALID_PASSWORD', ((ESignatureAPI.Error)e2).docuSignCode);

		System.assertNotEquals(null, e3);
		System.assert(e3 instanceof ESignatureAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e3.code);
		System.assertEquals('Authorization invalid token', e3.description);
		System.assertEquals('AUTHORIZATION_INVALID_TOKEN', ((ESignatureAPI.Error)e3).docuSignCode);

		System.assertNotEquals(null, e4);
		System.assert(e4 instanceof ESignatureAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e4.code);
		System.assertEquals('User authentication failed', e4.description);
		System.assertEquals('USER_AUTHENTICATION_FAILED', ((ESignatureAPI.Error)e4).docuSignCode);

		System.assertNotEquals(null, e5);
		System.assert(e5 instanceof ESignatureAPI.Error);
		System.assertEquals(APIErrorCode.BAD_REQUEST, e5.code);
		System.assertEquals('Some error', e5.description);
		System.assertEquals('SOME_ERROR', ((ESignatureAPI.Error)e5).docuSignCode);
	}

	@IsTest
	static void test_constructor_default_creds() {
		UserMock.createDocuSignAdministrator();

		System.runAs(UserMock.createDocuSignUser(false)) {
			Credentials credentials = Credentials.getInstance();
			System.assertNotEquals(null, credentials);
			System.assert(credentials.isValid);

			Test.startTest();
			ESignatureAPI c = ESignatureAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, c);
			System.assertNotEquals(null, c.baseUrl);
			System.assertNotEquals(null, c.userId);
			System.assertEquals(Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c), RestAPI.defaultTimeout);
		}
	}

	@IsTest
	static void test_constructor_failure() {
		Test.startTest();
		try {
			new ESignatureAPI(Credentials.getInstance());
			throw new AssertException('Expected DocuSignAPI constructor to throw exception when an account is not configured');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getBaseUrl() {
		System.runAs(UserMock.createDocuSignUser()) {
			ESignatureAPI client = ESignatureAPI.getInstance();

			Test.startTest();
			Url u = client.getBaseUrl();
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals(client.baseUrl.toExternalForm(), u.toExternalForm());
		}
	}

	@IsTest
	static void test_getDefaultHeaders() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Map<String, String> result = EnvelopeAPI.getInstance().getDefaultHeaders();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals('application/json', result.get('Content-Type'));
			System.assertEquals('application/json', result.get('Accept'));
			System.assertEquals('Bearer ' + Credentials.getInstance().token.token, result.get('Authorization'));
		}
	}

	@IsTest
	static void test_getError_exception() {
		System.runAs(UserMock.createDocuSignUser()) {
			ESignatureAPI client = ESignatureAPI.getInstance();
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
			ESignatureAPI client = ESignatureAPI.getInstance();
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
			System.assert(ESignatureAPI.getInstance().ping());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_ping_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			System.assert(!ESignatureAPI.getInstance().ping());
			Test.stopTest();
		}
	}
}
