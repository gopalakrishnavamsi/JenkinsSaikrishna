public with sharing class ScmTokenAPI extends ScmAPI {

	private static ScmTokenAPI self = null;

	private final UUID accountId;

	private ScmTokenAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(new Url(baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));

		this.accountId = accountId;
	}

	public static ScmTokenAPI getInstance() {
		if (self == null) {
			Url baseUrl = AccountProducts.getInstance().getScmMergeBaseUrl();
			if (baseUrl == null) throw new DocuSignException(Label.NegotiateNotConfigured);
			self = new ScmTokenAPI(
				baseUrl,
				'v1',
				Credentials.getInstance().account.id);
		}
		return self;
	}

	@TestVisible
	private class APILimitedAccessToken {
		public String accessToken;
		public String APIBaseUrl;
		public String APIUploadBaseUrl;
		public String APIDownloadBaseUrl;

		public LimitedAccessToken toExternalForm(
			final UUID accountId,
			final UUID entityId) {

			return new LimitedAccessToken(
				accessToken,
				accountId,
				entityId,
				APIBaseUrl,
				APIUploadBaseUrl,
				APIDownloadBaseUrl);
		}
	}

	public LimitedAccessToken generateLimitedAccessToken(
		final UUID entityId,
		final String accessToken) {

		return this.generateLimitedAccessToken(
			entityId,
			accessToken,
			RestAPI.defaultTimeout);
	}

	public LimitedAccessToken generateLimitedAccessToken(
		final UUID entityId,
		final String accessToken,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<String> { 'tokenregistrations' },
			JSON.serialize(new Map<String, Object> {
				'objectId' => String.valueOf(entityId),
				'accessToken' => accessToken
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to generate limited access token: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APILimitedAccessToken)JSON.deserialize(response.body, APILimitedAccessToken.class))
			.toExternalForm(this.accountId, entityId);
	}

	public Url getResourceToken(final UUID documentId) {
		return this.getResourceToken(
			documentId,
			RestAPI.defaultTimeout);
	}

	public Url getResourceToken(
		final UUID documentId,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'resourcetokenregistrations' },
			JSON.serialize(new Map<String, Object> {
				'objectid' => documentId.toString(),
				'objecttype' => 'document',
				'contenttype' => 'pdf',
				'requesttype' => 'inline'
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve resource token: ' + response.error);
			throw new APIException(response.error);
		}
		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url((String)body.get('secret_uri'));
	}

	public Url getCompareUrl(final UUID compareTaskId) {
		return this.getCompareUrl(
			compareTaskId,
			RestAPI.defaultTimeout);
	}

	public Url getCompareUrl(
		final UUID compareTaskId,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<Object> { 'resourcetokenregistrations' },
			JSON.serialize(new Map<String, Object> {
				'objectid' => compareTaskId.toString(),
				'objecttype' => 'transientdocument',
				'contenttype' => 'pdf',
				'requesttype' => 'inline'
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve Url for document comparison: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Url((String)body.get('secret_uri'));
	}
}
