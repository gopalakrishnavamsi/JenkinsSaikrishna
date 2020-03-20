@IsTest
public class ApplicationAPIMock extends OAuthTokenMock {

	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/(v1|v2)\\/applications\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})(\\/?(\\w+))?.*');
	private Boolean success;

	public ApplicationAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	public static ApplicationAPIMock success() {
		return (ApplicationAPIMock)TestUtils.setMock(new ApplicationAPIMock(true));
	}

	public static ApplicationAPIMock failure() {
		return (ApplicationAPIMock)TestUtils.setMock(new ApplicationAPIMock(false));
	}

	/*
		Supported paths:
			- POST /v2/applications/{{rootClientId}}/instance
			- DELETE /v1/applications/{{clientId}}
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		if (this.success) {
			String method = request.getMethod();
			String path = new Url(request.getEndpoint()).getPath();
			Matcher m = PATH_PATTERN.matcher(path);
			if (!m.matches()) throw new AssertException('Unexpected AuthAPI path: ' + path);
			String clientId = m.group(2);
			if (method == 'POST') {
				response.setStatusCode(200);
				response.setStatus('OK');
				String resource = String.isBlank(m.group(4)) ? 'application' : m.group(4);
				switch on resource {
					when 'instance' {
						response.setBody('{"secrets":[{"id":"' + UUID.randomUUID() + '","secret":"************abcd","type":"shared"},{"id":"' + UUID.randomUUID() + '","secret":"' + UUID.randomUUID() + '","type":"shared"}],"redirect_uris":["https://redirect1.unit.test", "https://redirect2.unit.test"],"private_key":"-----BEGIN RSA PRIVATE KEY-----\\n' + TestUtils.TEST_RSA_PRIVATE_KEY_BASE64 + '\\n-----END RSA PRIVATE KEY-----\\n","name":"Unit Test","client_id":"' + UUID.randomUUID() + '","parent_client_id":"' + clientId + '"}');
					} when else {
						throw new AssertException('Unexpected AuthAPI resource: ' + resource);
					}
				}
			} else if (method == 'DELETE') {
				response.setStatusCode(200);
				response.setStatus('OK');
			} else {
				throw new AssertException('Unexpected Auth API method: ' + method + ' ' + path);
			}
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"error":"unit_test","error_message":"Unit test error"}');
		}
		return response;
	}
}
