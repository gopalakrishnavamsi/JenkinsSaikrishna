public abstract class OAuthTokenMock implements HttpCalloutMock {

	private final Boolean bypass;

	public OAuthTokenMock() {
		this(false);
	}

	protected OAuthTokenMock(final Boolean bypass) {
		this.bypass = bypass;
	}

	public HttpResponse respond(final HttpRequest request) {
		if (this.bypass || request == null || request.getMethod() != 'POST' || !request.getEndpoint().contains('/oauth/token')) {
			return getResponse(request);
		}

		HttpResponse response = new HttpResponse();
		response.setStatusCode(200);
		response.setStatus('OK');
		response.setHeader('Content-Type', 'application/json; charset=utf-8');
		response.setBody(JSON.serialize(new Map<String, Object> {
			'access_token' => UUID.randomUUID().toString(),
			'token_type' => 'Bearer',
			'refresh_token' => UUID.randomUUID().toString(),
			'expires_in' => 28800
		}));
		return response;
	}

	public abstract HttpResponse getResponse(final HttpRequest request);
}
