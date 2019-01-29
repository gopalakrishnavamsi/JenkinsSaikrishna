public virtual class RestAPI {

	private static final Integer DEFAULT_TIMEOUT;
	public static Integer defaultTimeout {
		get {
			return DEFAULT_TIMEOUT;
		}
	}

	static {
		Integer timeout = Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c);
		DEFAULT_TIMEOUT = timeout == null ? 60000 : timeout;
	}

	private transient final Http http;
	protected transient LoggerService log { get; private set; }

	public class Response {
		public HttpRequest request { get; private set; }
		public HttpResponse response { get; private set; }
		public APIError error { get; private set; }
		public Boolean hasError { get; private set; }
		public Integer statusCode {
			get {
				return response == null ? 0 : response.getStatusCode();
			}
		}
		public String body {
			get {
				return response == null ? null : response.getBody();
			}
		}

		public Response(final HttpRequest request, final HttpResponse response, final APIError error) {
			this.request = request;
			this.response = response;
			this.error = error;
			this.hasError = error != null && error != APIError.none;
		}
	}

	@TestVisible
	protected RestAPI() {
		this.http = new Http();
		this.log = LoggerService.getInstance();
	}

	@TestVisible
	protected Response get(final Url baseUrl, final List<Object> path, final QueryString queryString, final Map<String, String> headers, final Integer timeout) {
		return sendRequest('GET', baseUrl, path, queryString, null, headers, null, timeout);
	}

	@TestVisible
	protected Response del(final Url baseUrl, final List<Object> path, final QueryString queryString, final Map<String, String> headers, final String body, final Integer timeout) {
		return sendRequest('DELETE', baseUrl, path, queryString, null, headers, body, timeout);
	}

	@TestVisible
	protected Response post(final Url baseUrl, final List<Object> path, final QueryString queryString, final Map<String, String> headers, final String body, final Integer timeout) {
		return sendRequest('POST', baseUrl, path, queryString, null, headers, body, timeout);
	}

	@TestVisible
	protected Response put(final Url baseUrl, final List<Object> path, final QueryString queryString, final Map<String, String> headers, final String body, final Integer timeout) {
		return sendRequest('PUT', baseUrl, path, queryString, null, headers, body, timeout);
	}

	/**
     * Make a http request
	 * @param Url  the request endpoint
	 * @param method  the http request method
	 * @param headers  a list of request headers
	 * @param reqBody  the request body
	 * @return HttpResponse  the http response of the request
     */
	@TestVisible
	private Response sendRequest(
		final String method,
		final Url baseUrl,
		final List<Object> path,
		final QueryString queryString,
		final String anchor,
		final Map<String, String> headers,
		final String reqBody,
		final Integer timeout) {

		// Build request Url
		String spec = '';
		Boolean prependSlash = false;
		for (Object p : (path == null ? new List<Object>() : path)) {
			final String s = String.valueOf(p);
			if (String.isNotBlank(s)) {
				if (prependSlash) { // Ensure the first path part is not absolute as it will overwrite the path portion of baseUrl.
					spec += '/' + StringUtils.encode(s);
				} else {
					spec += StringUtils.encode(s);
					prependSlash = true;
				}
			}
		}

		if (queryString != null && !queryString.isEmpty()) {
			spec += '?' + queryString.toString();
		}

		if (String.isNotBlank(anchor)) {
			spec += '#' + StringUtils.encode(anchor);
		}

		final HttpRequest request = new HttpRequest();
		request.setEndpoint(new Url(baseUrl, spec).toExternalForm());
		request.setTimeout(timeout);
		request.setMethod(method);

		if (String.isNotBlank(reqBody)) {
			request.setBody(reqBody);
		}

		if (headers != null) {
			for (String type : headers.keySet()) {
				request.setHeader(type, headers.get(type));
			}
		}
		request.setHeader('User-Agent', Application.userAgent);

		final HttpResponse response = http.send(request);
		return new Response(request, response, getError(response));
	}

	/**
	 * Validate the http response from DocuSign Rest service.
	 *              Checks the following:
	 *              1) Response is not null.
	 *              2) If the body is defined, Content-Type is application/json.
	 *              3) The HTTP status code is < 400.
	 * @param response the http response form DocuSign Rest service
	 * @return Error object
	 */
	@TestVisible
	protected virtual APIError getError(final HttpResponse response) {
		if (response == null) {
			return new APIError(APIErrorCode.NULL_RESPONSE, Label.NullApiResponse);
		} else {
			final Integer code = response.getStatusCode();
			final String contentType = response.getHeader('Content-Type');
			if (code >= 400) {
				return new APIError(code, response.getStatus());
			} else if (String.isNotBlank(response.getBody()) && (String.isBlank(contentType) || !contentType.startsWith('application/json'))) {
				log.warn('Response body was defined with invalid content type: ' + (String.isBlank(contentType) ? 'undefined' : contentType));
				return new APIError(APIErrorCode.INVALID_CONTENT_TYPE, Label.ContentTypeNotSupported);
			} else {
				return APIError.none;
			}
		}
	}
}
