public with sharing abstract class DocuSignAPI extends RestAPI {

	@TestVisible
	private Map<String, String> defaultHeaders;
	@TestVisible
	private final Url baseUrl;

	protected DocuSignAPI(final Url baseUrl) {
		if (baseUrl == null) throw UnauthorizedException.accountNotConfigured();
		if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		this.baseUrl = baseUrl;
	}

	@TestVisible
	protected virtual Url getBaseUrl() {
		return this.baseUrl;
	}

	@TestVisible
	protected virtual Map<String, String> getDefaultHeaders() {
		if (this.defaultHeaders == null) {
			this.defaultHeaders = new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Authorization' => 'Bearer ' + AuthService.getAccessToken()
			};
		}
		return this.defaultHeaders;
	}
}
