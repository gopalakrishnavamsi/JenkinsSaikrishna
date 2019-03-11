@IsTest
public with sharing class NegotiateAPIMock extends OAuthTokenMock {

    private final Boolean success;
    public static final String FOLDER_ID = '56322efe-e541-e911-9c1d-3ca82a1e3f41';

    public NegotiateAPIMock(final Boolean success) {
        this.success = success;
    }

    public static NegotiateAPIMock success() {
        return (NegotiateAPIMock) TestUtils.setMock(new NegotiateAPIMock(true));
    }

    public static NegotiateAPIMock failure() {
        return (NegotiateAPIMock) TestUtils.setMock(new NegotiateAPIMock(false));
    }

    /* Supported routes:
    - POST /folders - Create EOS folder in SpringCM Space
 */
    override public HttpResponse getResponse(final HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String method = request.getMethod();

        if (success && method == 'POST') {
            response.setStatusCode(201);
            response.setStatus('CREATED');
            response.setBody('{"Href":"https://unit.test/folders/' + FOLDER_ID + '"}');
        } else {
            response.setStatusCode(400);
            response.setStatus('BAD_REQUEST');
            response.setBody('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
        }

        return response;
    }

}
