public class NegotiateProduct extends Product {

	public static final String ROLE_NEGOTIATOR = 'Negotiator';

	public transient Url authBaseUrl { get; private set; }
	public transient Url apiBaseUrl { get; private set; }

	public NegotiateProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Url authBaseUrl,
		final Url apiBaseUrl) {

		super(
			Product.NEGOTIATE,
			status,
			isTrial,
			trialExpires);

		this.authBaseUrl = authBaseUrl;
		this.apiBaseUrl = apiBaseUrl;
	}
}
