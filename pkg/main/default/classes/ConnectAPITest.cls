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
	static void test_updateConfiguration_undefined_arguments() {
		System.runAs(UserMock.createDocuSignUser()) {
			Long id = TestUtils.randomInteger(10000000);
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test.docusign.net');
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.updateConfiguration(
					null,
					name,
					publishUrl,
					RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				client.updateConfiguration(
					id,
					' ',
					publishUrl,
					RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				client.updateConfiguration(
					id,
					name,
					null,
					RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateConfiguration_error() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Long id = TestUtils.randomInteger(10000000);
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test.docusign.net');
			ConnectAPI client = newClient();

			Test.startTest();
			try {
				client.updateConfiguration(
					id,
					name,
					publishUrl,
					RestAPI.defaultTimeout);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Long id = TestUtils.randomInteger(10000000);
			String name = UUID.randomUUID().toString();
			Url publishUrl = new Url('https://unit.test.docusign.net');
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertEquals(id, client.updateConfiguration(
				id,
				name,
				publishUrl,
				RestAPI.defaultTimeout));
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

	static final Long ID = TestUtils.randomInteger(10000000);
	static final String NAME = UUID.randomUUID().toString();
	static final Url PUBLISH_URL = new Url('https://' + UUID.randomUUID() + '.test.docusign.com');

	class CreateConfigurationUpdateMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			response.setStatus('OK');
			if (request.getMethod() == 'GET') {
				ConnectAPI.APIConfiguration config = new ConnectAPI.APIConfiguration(
					ID,
					NAME,
					PUBLISH_URL);
				config.requireMutualTls = 'false';
				config.allUsers = 'false';
				ConnectAPI.APIConfigurations configs = new ConnectAPI.APIConfigurations();
				configs.configurations = new List<ConnectAPI.APIConfiguration> { config };
				response.setBody(JSON.serialize(configs));
			} else if (request.getMethod() == 'PUT') {
				response.setBody(request.getBody());
			}
			return response;
		}
	}

	@IsTest
	static void test_createConfiguration_update() {
		Test.setMock(HttpCalloutMock.class, new CreateConfigurationUpdateMock());
		System.runAs(UserMock.createDocuSignUser()) {
			ConnectAPI client = newClient();

			Test.startTest();
			System.assertEquals(ID, client.createConfiguration(NAME, PUBLISH_URL));
			Test.stopTest();
		}
	}
}
