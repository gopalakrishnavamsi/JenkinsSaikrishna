@IsTest(isParallel = true)
private class RestAPITest {

	class RestAPIMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			final Url endpointUrl = new Url(request.getEndpoint());
			final QueryString qs = QueryString.parse(endpointUrl.getQuery());

			// parse out expected status code from port
			response.setStatusCode(endpointUrl.getPort());
			// and status from query string
			String status = qs.get('status');
			if (String.isNotBlank(status)) response.setStatus(StringUtils.decode(status));

			// parse out expected content-type from Accept header
			final String ct = request.getHeader('Accept');
			if (String.isNotBlank(ct)) response.setHeader('Content-Type', ct);

			// either use body from query string or echo request body, unless no-body is specified
			if (!endpointUrl.getPath().contains('no-body')) {

				String body = qs.get('body');
				if (String.isNotBlank(body)) response.setBody(StringUtils.decode(body)); else response.setBody(request.getBody());
			}

			return response;
		}
	}

	@IsTest
	static void test_defaultTimeout() {
		Test.startTest();
		System.assertEquals(60000, RestAPI.defaultTimeout);
		Test.stopTest();
	}

	@IsTest
	static void test_sendRequest() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response response = client.sendRequest(
			'GET',
			new Url('https://unit.test:200/'),
			new List<Object> { 'send', 'request' },
			new QueryString('body', '{"some":"value"}'),
			'anchor1',
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			null,
			30000);
		Test.stopTest();

		System.assertNotEquals(null, response);
		System.assertNotEquals(null, response.request);
		System.assertNotEquals(null, response.response);
		System.assertNotEquals(null, response.error);
		System.assertEquals('https://unit.test:200/send/request?body=%7B%22some%22%3A%22value%22%7D#anchor1', response.request.getEndpoint());
		System.assertEquals('application/json', response.request.getHeader('Accept'));
		System.assertEquals(200, response.statusCode);
		System.assertEquals('{"some":"value"}', response.body);
	}

	@IsTest
	static void test_getError_null_response() {
		final RestAPI client = new RestAPI();

		Test.startTest();
		final APIError error = client.getError(null);
		Test.stopTest();

		System.assertNotEquals(null, error);
		System.assertEquals(APIErrorCode.NULL_RESPONSE, error.code);
		System.assertEquals(Label.NullApiResponse, error.description);
	}

	@IsTest
	static void test_get_success() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.get(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			QueryString.empty,
			new Map<String, String>(),
			30000);
		final RestAPI.Response r2 = client.get(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			new QueryString(new Map<String, String> {
				'body' => '{"some":"json"}'
			}),
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('GET', r1.request.getMethod());
		System.assertEquals('https://unit.test:200/success', r1.request.getEndpoint());
		System.assert(!r1.hasError);
		System.assertEquals(APIError.none, r1.error);
		System.assertEquals(200, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('GET', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/success?body=%7B%22some%22%3A%22json%22%7D', r2.request.getEndpoint());
		System.assert(!r2.hasError);
		System.assertEquals(APIError.none, r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('application/json', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"json"}', r2.body);
	}

	@IsTest
	static void test_get_failure() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.get(
			new Url('https://unit.test:400/'),
			new List<Object> { 'failure' },
			new QueryString(new Map<String, String> {
				'status' => 'boo'
			}),
			new Map<String, String>(),
			30000);
		final RestAPI.Response r2 = client.get(
			new Url('https://unit.test:200/'),
			new List<Object> { 'failure' },
			new QueryString(new Map<String, String> {
				'body' => '{"some":"error"}'
			}),
			new Map<String, String> {
				'Accept' => 'text/html'
			},
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('GET', r1.request.getMethod());
		System.assertEquals('https://unit.test:400/failure?status=boo', r1.request.getEndpoint());
		System.assert(r1.hasError);
		System.assertEquals(new APIError(APIErrorCode.BAD_REQUEST, 'boo'), r1.error);
		System.assertEquals(400, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('GET', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/failure?body=%7B%22some%22%3A%22error%22%7D', r2.request.getEndpoint());
		System.assert(r2.hasError);
		System.assertEquals(new APIError(APIErrorCode.INVALID_CONTENT_TYPE, Label.ContentTypeNotSupported), r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('text/html', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"error"}', r2.body);
	}

	@IsTest
	static void test_post_success() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.post(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			QueryString.empty,
			new Map<String, String>(),
			'',
			30000);
		final RestAPI.Response r2 = client.post(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			'{"some":"json"}',
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('POST', r1.request.getMethod());
		System.assertEquals('https://unit.test:200/success', r1.request.getEndpoint());
		System.assert(!r1.hasError);
		System.assertEquals(APIError.none, r1.error);
		System.assertEquals(200, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('POST', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/success', r2.request.getEndpoint());
		System.assert(!r2.hasError);
		System.assertEquals(APIError.none, r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('application/json', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"json"}', r2.body);
	}

	@IsTest
	static void test_post_failure() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.post(
			new Url('https://unit.test:400/'),
			new List<Object> { 'failure', 'no-body' },
			new QueryString(new Map<String, String> {
				'status' => 'boo'
			}),
			new Map<String, String>(),
			'{"some":"error"}',
			30000);
		final RestAPI.Response r2 = client.post(
			new Url('https://unit.test:200/'),
			new List<Object> { 'failure' },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'text/html'
			},
			'{"some":"error"}',
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('POST', r1.request.getMethod());
		System.assertEquals('https://unit.test:400/failure/no-body?status=boo', r1.request.getEndpoint());
		System.assert(r1.hasError);
		System.assertEquals(new APIError(APIErrorCode.BAD_REQUEST, 'boo'), r1.error);
		System.assertEquals(400, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('POST', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/failure', r2.request.getEndpoint());
		System.assert(r2.hasError);
		System.assertEquals(new APIError(APIErrorCode.INVALID_CONTENT_TYPE, Label.ContentTypeNotSupported), r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('text/html', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"error"}', r2.body);
	}

	@IsTest
	static void test_put_success() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.put(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			'{"some":"json"}',
			30000);
		final RestAPI.Response r2 = client.put(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success', 'no-body' },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			'{"some":"json"}',
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('PUT', r1.request.getMethod());
		System.assertEquals('https://unit.test:200/success', r1.request.getEndpoint());
		System.assert(!r1.hasError);
		System.assertEquals(APIError.none, r1.error);
		System.assertEquals(200, r1.statusCode);
		System.assertEquals('application/json', r1.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"json"}', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('PUT', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/success/no-body', r2.request.getEndpoint());
		System.assert(!r2.hasError);
		System.assertEquals(APIError.none, r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('application/json', r2.response.getHeader('Content-Type'));
		System.assertEquals('', r2.body);
	}

	@IsTest
	static void test_put_failure() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.put(
			new Url('https://unit.test:400/'),
			new List<Object> { 'failure', 'no-body' },
			new QueryString(new Map<String, String> {
				'status' => 'boo'
			}),
			new Map<String, String>(),
			'',
			30000);
		final RestAPI.Response r2 = client.put(
			new Url('https://unit.test:200/'),
			new List<Object> { 'failure' },
			QueryString.empty,
			new Map<String, String> {
				'Accept' => 'text/xml'
			},
			'{"some":"error"}',
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('PUT', r1.request.getMethod());
		System.assertEquals('https://unit.test:400/failure/no-body?status=boo', r1.request.getEndpoint());
		System.assert(r1.hasError);
		System.assertEquals(new APIError(APIErrorCode.BAD_REQUEST, 'boo'), r1.error);
		System.assertEquals(400, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('PUT', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/failure', r2.request.getEndpoint());
		System.assert(r2.hasError);
		System.assertEquals(new APIError(APIErrorCode.INVALID_CONTENT_TYPE, Label.ContentTypeNotSupported), r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('text/xml', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"error"}', r2.body);
	}

	@IsTest
	static void test_del_success() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.del(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			QueryString.empty,
			new Map<String, String>(),
			null,
			30000);
		final RestAPI.Response r2 = client.del(
			new Url('https://unit.test:200/'),
			new List<Object> { 'success' },
			new QueryString(new Map<String, String> {
				'body' => '{"some":"json"}'
			}),
			new Map<String, String> {
				'Accept' => 'application/json'
			},
			null,
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('DELETE', r1.request.getMethod());
		System.assertEquals('https://unit.test:200/success', r1.request.getEndpoint());
		System.assert(!r1.hasError);
		System.assertEquals(APIError.none, r1.error);
		System.assertEquals(200, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('DELETE', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/success?body=%7B%22some%22%3A%22json%22%7D', r2.request.getEndpoint());
		System.assert(!r2.hasError);
		System.assertEquals(APIError.none, r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('application/json', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"json"}', r2.body);
	}

	@IsTest
	static void test_del_failure() {
		final RestAPI client = new RestAPI();
		Test.setMock(HttpCalloutMock.class, new RestAPIMock());

		Test.startTest();
		final RestAPI.Response r1 = client.del(
			new Url('https://unit.test:400/'),
			new List<Object> { 'failure' },
			new QueryString(new Map<String, String> {
				'status' => 'boo'
			}),
			new Map<String, String>(),
			null,
			30000);
		final RestAPI.Response r2 = client.del(
			new Url('https://unit.test:200/'),
			new List<Object> { 'failure' },
			new QueryString(new Map<String, String> {
				'body' => '{"some":"error"}'
			}),
			new Map<String, String> {
				'Accept' => 'application/pdf'
			},
			null,
			30000);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assertNotEquals(null, r1.request);
		System.assertNotEquals(null, r1.response);
		System.assertNotEquals(null, r1.error);
		System.assertEquals('DELETE', r1.request.getMethod());
		System.assertEquals('https://unit.test:400/failure?status=boo', r1.request.getEndpoint());
		System.assert(r1.hasError);
		System.assertEquals(new APIError(APIErrorCode.BAD_REQUEST, 'boo'), r1.error);
		System.assertEquals(400, r1.statusCode);
		System.assertEquals(null, r1.response.getHeader('Content-Type'));
		System.assertEquals('', r1.body);

		System.assertNotEquals(null, r2);
		System.assertNotEquals(null, r2.request);
		System.assertNotEquals(null, r2.response);
		System.assertNotEquals(null, r2.error);
		System.assertEquals('DELETE', r2.request.getMethod());
		System.assertEquals('https://unit.test:200/failure?body=%7B%22some%22%3A%22error%22%7D', r2.request.getEndpoint());
		System.assert(r2.hasError);
		System.assertEquals(new APIError(APIErrorCode.INVALID_CONTENT_TYPE, Label.ContentTypeNotSupported), r2.error);
		System.assertEquals(200, r2.statusCode);
		System.assertEquals('application/pdf', r2.response.getHeader('Content-Type'));
		System.assertEquals('{"some":"error"}', r2.body);
	}
}
