public with sharing abstract class ScmAPI extends DocuSignAPI {

	protected ScmAPI(final Url baseUrl) {
		super(baseUrl);
	}

	public class Error extends APIError {
		public UUID referenceId { get; private set; }

		public Error(
			final Integer code,
			final UUID referenceId,
			final String description) {

			super(code, description);

			this.referenceId = referenceId;
		}

		override public String toString() {
			return String.format(Label.ApiError_3, new List<String> {
				String.valueOf(this.code),
				this.description,
				String.valueOf(this.referenceId)
			});
		}
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> error = (Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body))
					.get('Error');
				e = new ScmAPI.Error(
					error.containsKey('ErrorCode') ? (Integer)error.get('ErrorCode') : statusCode,
					UUID.tryParse((String)error.get('ReferenceId')),
					error.containsKey('UserMessage') ? (String)error.get('UserMessage') : response.getStatus());
				this.log.warn('SpringCM API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse SpringCM API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
	}

	protected RestAPI.Response get(
		final List<Object> path,
		final Integer timeout) {

		return this.get(
			this.getBaseUrl(),
			path,
			QueryString.empty,
			this.getDefaultHeaders(),
			timeout);
	}

	protected RestAPI.Response get(
		final List<Object> path,
		final QueryString parameters,
		final Integer timeout) {

		return this.get(
			this.getBaseUrl(),
			path,
			parameters,
			this.getDefaultHeaders(),
			timeout);
	}

	protected RestAPI.Response post(
		final List<Object> path,
		final String body,
		final Integer timeout) {

		return this.post(
			this.getBaseUrl(),
			path,
			QueryString.empty,
			this.getDefaultHeaders(),
			body,
			timeout);
	}

	protected RestAPI.Response put(
		final List<Object> path,
		final String body,
		final Integer timeout) {

		return this.put(
			this.getBaseUrl(),
			path,
			QueryString.empty,
			this.getDefaultHeaders(),
			body,
			timeout);
	}

	protected RestAPI.Response del(
		final List<Object> path,
		final Integer timeout) {

		return this.del(
			this.getBaseUrl(),
			path,
			QueryString.empty,
			this.getDefaultHeaders(),
			null,
			timeout);
	}
}
