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
	private static Map<String, Object> getNode(
		final Map<String, Object> response,
		final List<String> path) {

		Map<String, Object> result = response;
		if (response != null && path != null) {
			for (Integer i = 0; i < path.size(); i++) {
				if (result == null) break;
				result = (Map<String, Object>)result.get(path[i]);
			}
		}
		return result;
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> errResp = (Map<String, Object>)JSON.deserializeUntyped(body);
				Map<String, Object> error = errResp == null ? null : (Map<String, Object>)errResp.get('Error'); // try V1
				if (error == null) { // try V2
					error = getNode(errResp, new List<String> { 'Extensions', 'additionalDetails', 'Error' });
				}
				if (error != null
					&& error.containsKey('ErrorCode')
					&& error.containsKey('ReferenceId')
					&& error.containsKey('UserMessage')) { // understood SCM error

					e = new ScmAPI.Error(
						(Integer)error.get('ErrorCode'),
						UUID.tryParse((String)error.get('ReferenceId')),
						(String)error.get('UserMessage'));
				} else { // did not understand SCM error
					this.log.error('Failed to parse SpringCM API error. Response body:\n' + body);
					e = new ScmAPI.Error(
						statusCode,
						null,
						response.getStatus());
				}
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
