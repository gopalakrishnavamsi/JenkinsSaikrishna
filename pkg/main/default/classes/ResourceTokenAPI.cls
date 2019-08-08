public with sharing class ResourceTokenAPI extends DocuSignAPI {
	public static String PATH_RESOURCETOKEN = 'resourcetokenregistrations';
	private static ResourceTokenAPI self = null;

	@TestVisible
	private ResourceTokenAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super (new Url (baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static ResourceTokenAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			if (c.environment.scmApiBaseUrl != null && c.account.id != null) {
				self = new ResourceTokenAPI(c.environment.scmApiBaseUrl, 'v1', c.account.id);
			} else {
				throw UnauthorizedException.accountNotConfigured();
			}
		}
		return self;
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
				e = new ResourceTokenAPI.Error(
					error.containsKey('ErrorCode') ? (Integer)error.get('ErrorCode') : statusCode,
					UUID.tryParse((String)error.get('ReferenceId')),
					error.containsKey('UserMessage') ? (String)error.get('UserMessage') : response.getStatus());
				this.log.warn('ResourceToken API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse ResourceToken API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
	}

	public Url getResourceToken(final UUID documentId) {
		RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> { PATH_RESOURCETOKEN },
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'objectid' => documentId.toString(),
				'objecttype' => 'document',
				'contenttype' => 'pdf',
				'requesttype' => 'inline'
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve resource token: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url(
			(String) body.get('secret_uri')
		);	
	}
}

