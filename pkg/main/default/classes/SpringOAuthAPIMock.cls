@IsTest
public class SpringOAuthAPIMock extends OAuthTokenMock {

	private final Boolean success;

	public SpringOAuthAPIMock(final Boolean success) {
		this.success = success;
	}

	// Handles POST SetupSalesforce/DALIntegration
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json; charset=utf-8');
		if (this.success) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{}');
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
		}
		return response;
	}
}
