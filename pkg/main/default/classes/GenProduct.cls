public class GenProduct extends Product {

	public static final String ROLE_GENERATOR = 'Generator';

	public transient Url webBaseUrl { get; private set; }
	public transient Url apiBaseUrl { get; private set; }
	public transient Url mergeBaseUrl { get; private set; }

	public GenProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Url webBaseUrl,
		final Url apiBaseUrl,
		final Url mergeBaseUrl) {

		super(
			Product.GEN,
			status,
			isTrial,
			trialExpires);

		if ((webBaseUrl != null && !DocuSign.isValidUrl(webBaseUrl))
			|| (apiBaseUrl != null && !DocuSign.isValidUrl(apiBaseUrl))
			|| (mergeBaseUrl != null && !DocuSign.isValidUrl(mergeBaseUrl))) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		this.webBaseUrl = UrlUtils.canonicalizeBaseUrl(webBaseUrl);
		this.apiBaseUrl = UrlUtils.canonicalizeBaseUrl(apiBaseUrl);
		this.mergeBaseUrl = UrlUtils.canonicalizeBaseUrl(mergeBaseUrl);
	}
}
