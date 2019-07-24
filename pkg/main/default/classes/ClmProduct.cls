public class ClmProduct extends Product {

	// TODO: Need CLM-specific properties?

	public ClmProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Map<String, String> properties) {

		super(
			Product.NAME_CLM,
			status,
			isTrial,
			trialExpires,
			properties);
	}
}
