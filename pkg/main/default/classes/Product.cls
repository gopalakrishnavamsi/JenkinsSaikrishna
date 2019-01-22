public class Product {

	public String name { get; private set; }
	public String status { get; private set; }
	public Boolean isTrial { get; private set; }
	public Datetime trialExpires { get; private set; }
	public Map<String, String> properties { get; private set; }

	public Product(
		final String name,
		final String status,
		final Boolean isTrial,
		final Datetime trialExpires,
		final Map<String, String> properties) {

		this.name = name;
		this.status = status;
		this.isTrial = isTrial == true;
		this.trialExpires = trialExpires;
		this.properties = properties == null ? new Map<String, String>() : properties;
	}
}
