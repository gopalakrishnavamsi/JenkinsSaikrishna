@IsTest
public class CLMAPIMock extends OAuthTokenMock {

	private final Boolean success;

	public CLMAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	public static CLMAPIMock success() {
		return (CLMAPIMock)TestUtils.setMock(new CLMAPIMock(true));
	}

	public static CLMAPIMock failure() {
		return (CLMAPIMock)TestUtils.setMock(new CLMAPIMock(false));
	}

	/*
		Supported paths:
			- POST api/v1/
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		if (this.success) {
			String method = request.getMethod();
			String path = new Url(request.getEndpoint()).getPath();
			if (method == 'POST' && path.startsWith('/api/v1/')) {
				
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody(JSON.serialize(new map<String,String>{
                    'access_token'=>TestUtils.randomString(40),
                        'Url'=>'https://authqa.springcm.com'
				}));
			} else {
				throw new AssertException('Unexpected OAuth request: ' + method + ' ' + path);
			}
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"error":"unit_test","error_message":"Unit test error"}');
		}
		return response;
	}
}