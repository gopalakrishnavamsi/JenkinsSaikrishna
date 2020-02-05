public class LimitedAccessToken {
	@AuraEnabled
	public String token { get; private set; }
	@AuraEnabled
	public String apiBaseUrl { get; private set; }
	@AuraEnabled
	public UUID accountId { get; private set; }
	@AuraEnabled
	public UUID entityId { get; private set; }
	@AuraEnabled
	public String apiUploadBaseUrl { get; private set; }
	@AuraEnabled
	public String apiDownloadBaseUrl { get; private set; }

	public LimitedAccessToken(
		final String token,
		final UUID accountId,
		final UUID entityId,
		final String apiBaseUrl,
		final String apiUploadBaseUrl,
		final String apiDownloadBaseUrl) {

		this.token = token;
		this.accountId = accountId;
		this.entityId = entityId;
		this.apiBaseUrl = apiBaseUrl;
		this.apiUploadBaseUrl = apiUploadBaseUrl != null ? apiUploadBaseUrl.split('/v')[0] : null;
		this.apiDownloadBaseUrl = apiDownloadBaseUrl != null ? apiDownloadBaseUrl.split('/v')[0] : null;
	}
}
