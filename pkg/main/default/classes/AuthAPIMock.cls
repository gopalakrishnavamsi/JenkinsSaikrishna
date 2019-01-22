@IsTest
public class AuthAPIMock extends OAuthTokenMock {

	private static final Pattern PATH_PATTERN = Pattern.compile(
		'\\/v1\\/applications\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\d+)\\/(\\w+).*');
	private Boolean success;

	public AuthAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	public static AuthAPIMock success() {
		return (AuthAPIMock)TestUtils.setMock(new AuthAPIMock(true));
	}

	public static AuthAPIMock failure() {
		return (AuthAPIMock)TestUtils.setMock(new AuthAPIMock(false));
	}

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
				switch on m.group(2) {
					when 'instance' {
						response.setBody('{"name":"Unit Test","client_id":"' + UUID.randomUUID() + '","parent_client_id":"' + clientId + '"}');
					} when 'secrets' {
						response.setBody('{"id":"' + UUID.randomUUID() + '","name":"Unit Test","account_id":"' + UUID.randomUUID() + '","client_id":"' + clientId + '","secrets":[{"id":"' + UUID.randomUUID() + '","secret":"************abcd","type":"shared"},{"id":"' + UUID.randomUUID() + '","secret":"' + UUID.randomUUID() + '","type":"shared"}],"is_client_application":false}');
					} when 'keys' {
						response.setBody('{"client_id":"' + clientId + '","key_id":"' + UUID.randomUUID() + '","key_size":2048,"private_key":"-----BEGIN RSA PRIVATE KEY-----\\n' + TestUtils.TEST_RSA_PRIVATE_KEY_BASE64 + '\\n-----END RSA PRIVATE KEY-----\\n"}');
					} when else {
						throw new AssertException('Unexpected AuthAPI operation: ' + m.group(2));
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
