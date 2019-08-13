public class ClmProduct extends Product {

	public static final String ROLE_ADMINISTRATOR = 'Administrator';
	public static final String ROLE_USER = 'User';
	public static final String ROLE_VIEWER = 'Viewer';

	public transient Url authBaseUrl { get; private set; }
	public transient Url landingPageUrl { get; private set; }
	public transient Url adminUrl { get; private set; }

	public ClmProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Url authBaseUrl,
		final Url landingPageUrl,
		final Url adminUrl) {

		super(
			Product.CLM,
			status,
			isTrial,
			trialExpires);

		this.authBaseUrl = authBaseUrl;
		this.landingPageUrl = landingPageUrl;
		this.adminUrl = adminUrl;
	}
}
