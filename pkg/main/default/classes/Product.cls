public abstract class Product {

	public static final String ESIGNATURE = 'e_sign';
	public static final String GEN = 'gen';
	public static final String NEGOTIATE = 'negotiate';
	public static final String CLM = 'clm';
	private static final Set<String> VALID_PRODUCTS = new Set<String> {
		ESIGNATURE, GEN, NEGOTIATE, CLM
	};

	public static final String STATUS_PENDING = 'pending';
	public static final String STATUS_ACTIVE = 'active';
	public static final String STATUS_EXPIRED = 'expired';

	@AuraEnabled
	public String name { get; private set; }
	@AuraEnabled
	public String status { get; private set; }
	@AuraEnabled
	public Boolean isTrial { get; private set; }
	@AuraEnabled
	public Date trialExpires { get; private set; }
	@AuraEnabled
	public Boolean isExpired {
		get {
			return this.isTrial
				&& this.trialExpires < Date.today();
		}
	}
	@AuraEnabled
	public Integer daysUntilExpires {
		get {
			if (!this.isTrial || this.isExpired) return 0;

			return Math.max(Date.today().daysBetween(this.trialExpires), 0);
		}
	}

	protected Product(
		final String name,
		final String status,
		final Boolean isTrial,
		final Date trialExpires) {

		this.name = name;
		this.status = status;
		this.isTrial = isTrial == true;
		this.trialExpires = trialExpires;
	}

	public static Boolean isValidProduct(final String productName) {
		return String.isNotBlank(productName) && VALID_PRODUCTS.contains(productName.toLowerCase());
	}

	public class Role {
		public UUID id { get; private set; }
		public Long groupId { get; private set; }
		public String product { get; private set; }
		public String name { get; private set; }
		public String description { get; private set; }
		public Boolean isAdministrator { get; private set; }

		public Role(
			final UUID id,
			final Long groupId,
			final String product,
			final String name,
			final String description,
			final Boolean isAdministrator) {

			this.id = id;
			this.groupId = groupId;
			this.product = product;
			this.name = name;
			this.description = description;
			this.isAdministrator = isAdministrator;
		}
	}
}
