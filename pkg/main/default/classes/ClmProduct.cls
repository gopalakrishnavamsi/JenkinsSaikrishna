public class ClmProduct extends Product {

	public static final String ROLE_ADMINISTRATOR = 'Administrator';
	public static final String ROLE_USER = 'User';
	public static final String ROLE_VIEWER = 'Viewer';

	public transient Url webBaseUrl { get; private set; }
	public transient Url authBaseUrl { get; private set; }

	public ClmProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Url webBaseUrl,
		final Url authBaseUrl) {

		super(
			Product.CLM,
			status,
			isTrial,
			trialExpires);

		if ((webBaseUrl != null && !DocuSign.isValidUrl(webBaseUrl))
			|| (authBaseUrl != null && !DocuSign.isValidUrl(authBaseUrl))) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		this.webBaseUrl = UrlUtils.canonicalizeBaseUrl(webBaseUrl);
		this.authBaseUrl = UrlUtils.canonicalizeBaseUrl(authBaseUrl);
	}
}
