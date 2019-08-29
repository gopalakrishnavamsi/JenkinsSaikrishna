@IsTest(IsParallel = true)
private class ScmAPITest {

	class TestAPI extends ScmAPI {

		public TestAPI(final Url baseUrl) {
			super(baseUrl);
		}
	}

	@IsTest
	static void test_getBaseUrl() {
		UUID accountId = UUID.randomUUID();
		TestAPI client = new TestAPI(new Url('https://test.springcm.com/v2/' + accountId + '/'));

		Test.startTest();
		Url result = client.getBaseUrl();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.format('https://test.springcm.com/v2/{0}/',
			new List<Object> { accountId }), result.toExternalForm());
	}

	@IsTest
	static void test_getError() {
		TestAPI client = new TestAPI(new Url('https://test.springcm.com/'));

		HttpResponse r1 = new HttpResponse();
		r1.setStatusCode(200);
		System.assertEquals(APIError.none, client.getError(r1));

		HttpResponse r2 = new HttpResponse();
		r2.setStatusCode(401);
		r2.setBody('{"Error":{"HttpStatusCode":500,"UserMessage":"User","DeveloperMessage":"Developer","ErrorCode":1234,"ReferenceId":"11111111-1111-1111-1111-111111111111"}}');
		APIError e2 = client.getError(r2);
		System.assertNotEquals(null, e2);
		System.assertEquals(1234, e2.code);
		System.assertEquals('User', e2.description);
		System.assert(e2 instanceof ScmAPI.Error);
		System.assertEquals(UUID.parse('11111111-1111-1111-1111-111111111111'), ((ScmAPI.Error)e2).referenceId);

		HttpResponse r3 = new HttpResponse();
		r3.setStatusCode(422);
		r3.setStatus('UNIT_TEST');
		APIError e3 = client.getError(r3);
		System.assertEquals(422, e3.code);
		System.assertEquals('UNIT_TEST', e3.description);
		System.assert(!(e3 instanceof ScmAPI.Error));
	}
}
