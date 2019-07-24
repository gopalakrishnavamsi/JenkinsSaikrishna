public class NegotiateProduct extends Product {

	// TODO: Need Negotiate-specific properties?

	public NegotiateProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Map<String, String> properties) {

		super(
			Product.NAME_NEGOTIATE,
			status,
			isTrial,
			trialExpires,
			properties);
	}
}
