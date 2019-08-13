public with sharing abstract class ProvisioningAPI extends DocuSignAPI {

	private Map<String, String> defaultHeaders = null;
	private final String accessToken;

	protected ProvisioningAPI(
		final Url baseUrl,
		final String path,
		final String accessToken) {

		super(new Url(baseUrl, path));

		this.accessToken = accessToken;
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
				Map<String, Object> error = (Map<String, Object>)JSON.deserializeUntyped(body);
				e = new ProvisioningAPI.Error(
					statusCode,
					UUID.tryParse((String)error.get('reference_id')),
					(String)error.get('error_description')); // OR error_description?
				this.log.warn('Provisioning API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse provisioning API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
	}

	@TestVisible
	override protected Map<String, String> getDefaultHeaders() {
		if (this.defaultHeaders == null) {
			this.defaultHeaders = new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Authorization' => 'Bearer ' + (String.isBlank(this.accessToken)
					? AuthService.getAccessToken() : this.accessToken)
			};
		}
		return this.defaultHeaders;
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
		final QueryString parameters,
		final String body,
		final Integer timeout) {

		return this.post(
			this.getBaseUrl(),
			path,
			parameters,
			this.getDefaultHeaders(),
			body,
			timeout);
	}

	protected RestAPI.Response del(
		final List<Object> path,
		final QueryString parameters,
		final String body,
		final Integer timeout) {

		return this.del(
			this.getBaseUrl(),
			path,
			parameters,
			this.getDefaultHeaders(),
			body,
			timeout);
	}
}
