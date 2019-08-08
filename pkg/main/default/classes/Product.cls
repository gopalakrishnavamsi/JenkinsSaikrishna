public abstract class Product {

	public static final String ESIGNATURE = 'e_sign';
	public static final String GEN = 'gen';
	public static final String NEGOTIATE = 'negotiate';
	public static final String CLM = 'clm';

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
}
