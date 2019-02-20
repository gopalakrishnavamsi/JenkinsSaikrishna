@IsTest
public class GenAPIMock extends OAuthTokenMock {

	private final Boolean success;

	public GenAPIMock(final Boolean success) {
		this.success = success;
	}

	/* Supported routes:
		- POST /gen - queue document generation
		- GET /gen/{jobId} - check job status
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		String method = request.getMethod();
		if (success && method == 'GET') {
			// Return last modified ContentVersion.Id. No good way to mock this without mixing in test code.
			ContentVersion cv = (ContentVersion)Collection.head([SELECT Id FROM ContentVersion ORDER BY LastModifiedDate DESC LIMIT 1]);
			Id cvId = cv == null ? null : cv.Id;
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"SfContentVersionId":' + JSON.serialize(cvId) + ',"Status":"Success","Message":"Test success message"}');
		} else if (success && method == 'POST') {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Href":"https://unit.test/gen/' + UUID.randomUUID() + '"}');
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
		}
		return response;
	}

	public static GenAPIMock success() {
		return (GenAPIMock)TestUtils.setMock(new GenAPIMock(true));
	}

	public static GenAPIMock failure() {
		return (GenAPIMock)TestUtils.setMock(new GenAPIMock(false));
	}
}
