@IsTest
private class ProvisioningAPITest {

	class TestAPI extends ProvisioningAPI {

		public TestAPI(
			final Url baseUrl,
			final UUID accountId,
			final String accessToken) {

			super(
				baseUrl,
				String.format('/test/v1/provision/accounts/{0}', new List<Object> { accountId }),
				accessToken);
		}
	}

	@IsTest
	static void test_getBaseUrl() {
		System.runAs(UserMock.createDocuSignUser()) {
			Url baseUrl = new Url('https://test.docusign.net/');
			UUID accountId = UUID.randomUUID();
			String accessToken = 'unit.test';
			TestAPI client = new TestAPI(baseUrl, accountId, accessToken);

			Test.startTest();
			Url result = client.getBaseUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(String.format('https://test.docusign.net/test/v1/provision/accounts/{0}',
				new List<Object> { accountId }), result.toExternalForm());
		}
	}

	@IsTest
	static void test_getDefaultHeaders() {
		System.runAs(UserMock.createDocuSignUser()) {
			Url baseUrl = new Url('https://test.docusign.net/');
			UUID accountId = UUID.randomUUID();
			String accessToken = 'unit.test';
			TestAPI client = new TestAPI(baseUrl, accountId, accessToken);

			Test.startTest();
			Map<String, String> result = client.getDefaultHeaders();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals('application/json', result.get('Content-Type'));
			System.assertEquals('application/json', result.get('Accept'));
			System.assertEquals('Bearer ' + accessToken, result.get('Authorization'));
		}
	}

	@IsTest
	static void test_getError() {
		System.runAs(UserMock.createDocuSignUser()) {
			ProductAPI client = ProductAPI.getInstance();

			HttpResponse r1 = new HttpResponse();
			r1.setStatusCode(200);
			System.assertEquals(APIError.none, client.getError(r1));

			HttpResponse r2 = new HttpResponse();
			r2.setStatusCode(401);
			r2.setBody('{"error":"not_authorized","error_description":"no way","reference_id":"01234567-89ab-cdef-0123-456789abcdef"}');
			APIError e2 = client.getError(r2);
			System.assertNotEquals(null, e2);
			System.assertEquals(401, e2.code);
			System.assertEquals('no way', e2.description);
			System.assert(e2 instanceof ProvisioningAPI.Error);
			System.assertEquals(UUID.parse('01234567-89ab-cdef-0123-456789abcdef'), ((ProvisioningAPI.Error)e2).referenceId);

			HttpResponse r3 = new HttpResponse();
			r3.setStatusCode(422);
			r3.setStatus('UNIT_TEST');
			APIError e3 = client.getError(r3);
			System.assertEquals(422, e3.code);
			System.assertEquals('UNIT_TEST', e3.description);
			System.assert(!(e3 instanceof ProvisioningAPI.Error));
		}
	}
}
