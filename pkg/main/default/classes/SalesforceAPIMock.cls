@IsTest
public class SalesforceAPIMock implements HttpCalloutMock {

	private final Boolean success;

	public SalesforceAPIMock(final Boolean success) {
		this.success = success;
	}

	public HttpResponse respond(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		if (this.success
			&& request.getMethod() == 'POST'
			&& request.getEndpoint().endsWith('/services/oauth2/token')) {

			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"access_token":"unit.test"}');
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"error":"invalid_grant","error_description":"consent required"}');
		}
		return response;
	}

	public static SalesforceAPIMock success() {
		return (SalesforceAPIMock)TestUtils.setMock(new SalesforceAPIMock(true));
	}

	public static SalesforceAPIMock failure() {
		return (SalesforceAPIMock)TestUtils.setMock(new SalesforceAPIMock(false));
	}
}
