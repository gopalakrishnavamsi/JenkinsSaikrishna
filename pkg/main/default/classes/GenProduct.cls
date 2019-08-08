public class GenProduct extends Product {

	public transient Url authBaseUrl { get; private set; }
	public transient Url apiBaseUrl { get; private set; }

	public GenProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Url authBaseUrl,
		final Url apiBaseUrl) {

		super(
			Product.GEN,
			status,
			isTrial,
			trialExpires);

		this.authBaseUrl = authBaseUrl;
		this.apiBaseUrl = apiBaseUrl;
	}
}
