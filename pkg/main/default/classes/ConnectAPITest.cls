@IsTest
private class ConnectAPITest {

	@IsTest
	static void test_getInstance_undefined_arguments() {
		Url baseUrl = new Url('https://unit.test.docusign.net/');
		UUID accountId = UUID.randomUUID();
		String accessToken = 'unit.test';

		Test.startTest();
		try {
			ConnectAPI.getInstance(null, accountId, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ConnectAPI.getInstance(baseUrl, null, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ConnectAPI.getInstance(null, UUID.empty, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getInstance_invalid_url() {
		Url baseUrl = new Url('https://unit.test.evil-docusign.net/');
		UUID accountId = UUID.randomUUID();
		String accessToken = 'unit.test';

		Test.startTest();
		try {
			ConnectAPI.getInstance(baseUrl, accountId, accessToken);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		Test.stopTest();
	}
	
	static ConnectAPI newClient() {
		return ConnectAPI.getInstance(
			new Url('https://unit.test.docusign.net'),
			UUID.randomUUID(),
			'unit.test');
	}

	@IsTest
	static void test_getConfiguration_undefined_arguments() {
		System.runAs(UserMock.createDocuSignUser()) {
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.getConfiguration(null, RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_error() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Url publishUrl = new Url('https://unit.test');
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.getConfiguration(publishUrl, RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_success_found() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Url publishUrl = new Url('https://unit.test');
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertNotEquals(null, client.getConfiguration(publishUrl, RestAPI.defaultTimeout));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_success_not_found() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Url publishUrl = new Url('https://unit.test.other');
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertEquals(null, client.getConfiguration(publishUrl, RestAPI.defaultTimeout));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createConfiguration_undefined_arguments() {
		System.runAs(UserMock.createDocuSignUser()) {
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test');
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.createConfiguration(null, publishUrl);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				client.createConfiguration(' ', publishUrl);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				client.createConfiguration(name, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class CreateConfigurationErrorMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			if (request.getMethod() == 'GET') {
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody('{"configurations":null}');
			} else {
				response.setStatusCode(400);
				response.setStatus('BAD_REQUEST');
				response.setHeader('Content-Type', 'application/json; charset=utf-8');
				response.setBody('{"errorCode":"UNIT_TEST","message":"Unit test error"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_createConfiguration_error() {
		Test.setMock(HttpCalloutMock.class, new CreateConfigurationErrorMock());
		System.runAs(UserMock.createDocuSignUser()) {
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test');
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.createConfiguration(name, publishUrl);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createConfiguration_success_exists() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test');
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertNotEquals(null, client.createConfiguration(name, publishUrl));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createConfiguration_success_new() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test.other');
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertNotEquals(null, client.createConfiguration(name, publishUrl));
			Test.stopTest();
		}
	}
}
