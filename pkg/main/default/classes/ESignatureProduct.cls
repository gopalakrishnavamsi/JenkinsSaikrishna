public class ESignatureProduct extends Product {

	public enum Feature { MergeFields, Templates, SigningGroups, SmsAuthentication, BulkSending }

	public Set<Feature> features { get; private set; }

	@AuraEnabled
	public Boolean bulkSending {
		get {
			return this.features.contains(Feature.BulkSending);
		}
	}
	@AuraEnabled
	public Boolean mergeFields {
		get {
			return this.features.contains(Feature.MergeFields);
		}
	}
	@AuraEnabled
	public Boolean signingGroups {
		get {
			return this.features.contains(Feature.SigningGroups);
		}
	}
	@AuraEnabled
	public Boolean smsAuthentication {
		get {
			return this.features.contains(Feature.SmsAuthentication);
		}
	}
	@AuraEnabled
	public Boolean templates {
		get {
			return this.features.contains(Feature.Templates);
		}
	}

	public ESignatureProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Set<Feature> features) {

		super(
			Product.NAME_ESIGNATURE,
			status,
			isTrial,
			trialExpires,
			null);

		this.features = features == null ? new Set<Feature>() : features;
	}
}
