public class GenProduct extends Product {

	// TODO: Need Gen-specific properties?

	public GenProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Map<String, String> properties) {

		super(
			Product.NAME_GEN,
			status,
			isTrial,
			trialExpires,
			properties);
	}
}
