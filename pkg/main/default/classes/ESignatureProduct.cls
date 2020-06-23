public class ESignatureProduct extends Product {

	public static final String ROLE_ADMINISTRATOR = 'Administrator';
	public static final String ROLE_USER = 'User';
	public static final String ROLE_SENDER = 'Sender';

	public enum Feature { MergeFields, Templates, SigningGroups, SmsAuthentication, BulkSending, Connect }

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
	@AuraEnabled
	public Boolean connect {
		get {
			return this.features.contains(Feature.Connect);
		}
	}

	public ESignatureProduct(
		final String status,
		final Boolean isTrial,
		final Date trialExpires,
		final Set<Feature> features) {

		super(
			Product.ESIGNATURE,
			status,
			isTrial,
			trialExpires);

		this.features = features == null ? new Set<Feature>() : features;
	}
}
