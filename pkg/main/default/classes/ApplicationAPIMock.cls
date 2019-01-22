@IsTest
public class ApplicationAPIMock extends OAuthTokenMock {

	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/v1\\/applications\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})(\\/?(\\w+))?.*');
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
			- POST /v1/application/{{client-id}}
			- POST /v1/application/{{client-id}}/instance
			- POST /v1/application/{{client-id}}/secrets
			- POST /v1/application/{{client-id}}/keys
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		if (this.success) {
			String method = request.getMethod();
			String path = new Url(request.getEndpoint()).getPath();
			if (method == 'POST') {
				Matcher m = PATH_PATTERN.matcher(path);
				if (!m.matches()) throw new AssertException('Unexpected AuthAPI path: ' + path);
				response.setStatusCode(200);
				response.setStatus('OK');
				String clientId = m.group(1);
				String resource = String.isBlank(m.group(3)) ? 'application' : m.group(3);
				switch on resource {
					when 'instance' {
						response.setBody('{"name":"Unit Test","client_id":"' + UUID.randomUUID() + '","parent_client_id":"' + clientId + '"}');
					} when 'secrets' {
						response.setBody('{"id":"' + UUID.randomUUID() + '","name":"Unit Test","account_id":"' + UUID.randomUUID() + '","client_id":"' + clientId + '","secrets":[{"id":"' + UUID.randomUUID() + '","secret":"************abcd","type":"shared"},{"id":"' + UUID.randomUUID() + '","secret":"' + UUID.randomUUID() + '","type":"shared"}],"is_client_application":false}');
					} when 'keys' {
						response.setBody('{"client_id":"' + clientId + '","key_id":"' + UUID.randomUUID() + '","key_size":2048,"private_key":"-----BEGIN RSA PRIVATE KEY-----\\n' + TestUtils.TEST_RSA_PRIVATE_KEY_BASE64 + '\\n-----END RSA PRIVATE KEY-----\\n"}');
					} when 'application' {
						response.setBody(request.getBody());
					} when else {
						throw new AssertException('Unexpected AuthAPI resource: ' + resource);
					}
				}
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
