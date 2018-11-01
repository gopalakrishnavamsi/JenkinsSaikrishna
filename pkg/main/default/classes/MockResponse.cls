@IsTest
public class MockResponse {

	public Integer statusCode { get; private set; }
	public String status { get; private set; }
	public String contentType { get; private set; }
	public String body { get; private set; }

	public MockResponse(
		final Integer statusCode,
		final String status,
		final String contentType,
		final String body) {

		this.statusCode = statusCode;
		this.status = status;
		this.contentType = contentType;
		this.body = body;
	}

	private static String getJson(final Object body) {
		if (body == null) return '{}';
		if (body instanceof String) return (String)body;
		return JSON.serialize(body);
	}

	public static MockResponse ok(final Object body) {
		return new MockResponse(
			200,
			'OK',
			'application/json; charset=utf-8',
			getJson(body));
	}

	public static MockResponse created(final Object body) {
		return new MockResponse(
			201,
			'CREATED',
			'application/json; charset=utf-8',
			getJson(body));
	}

	public static MockResponse badRequest(final Object body) {
		return new MockResponse(
			400,
			'BAD_REQUEST',
			'application/json; charset=utf-8',
			getJson(body));
	}

	public static MockResponse unauthorized(final Object body) {
		return new MockResponse(
			401,
			'UNAUTHORIZED',
			'application/json; charset=utf-8',
			getJson(body));
	}

	public static MockResponse notImplemented(final String method, final String resource) {
		return new MockResponse(
			501,
			'NOT_IMPLEMENTED',
			'application/json; charset=utf-8',
			'{"errorCode":"MOCK_NOT_IMPLEMENTED","message":"Test mock not implemented for '
				+ method + ' ' + resource + '"}');
	}
}