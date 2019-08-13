/**
 * A DocuSign product.
 */
public abstract class Product {
	/**
	 * DocuSign eSignature product name.
	 */
	public static final String ESIGNATURE = 'e_sign';
	/**
	 * DocuSign Gen product name.
	 */
	public static final String GEN = 'gen';
	/**
	 * DocuSign Negotiate product name.
	 */
	public static final String NEGOTIATE = 'negotiate';
	/**
	 * DocuSign CLM product name.
	 */
	public static final String CLM = 'clm';
	private static final Map<String, Set<String>> VALID_PRODUCT_ROLES = new Map<String, Set<String>> {
		ESIGNATURE => new Set<String> {
			ESignatureProduct.ROLE_ADMINISTRATOR.toLowerCase(),
			ESignatureProduct.ROLE_USER.toLowerCase(),
			ESignatureProduct.ROLE_SENDER.toLowerCase()
		},
		GEN => new Set<String> {
			GenProduct.ROLE_GENERATOR.toLowerCase()
		},
		NEGOTIATE => new Set<String> {
			NegotiateProduct.ROLE_NEGOTIATOR.toLowerCase()
		},
		CLM => new Set<String> {
			ClmProduct.ROLE_ADMINISTRATOR.toLowerCase(),
			ClmProduct.ROLE_USER.toLowerCase(),
			ClmProduct.ROLE_VIEWER.toLowerCase()
		}
	};

	/**
	 * Product is pending activation on the account.
	 */
	public static final String STATUS_PENDING = 'pending';
	/**
	 * Product is active on the account.
	 */
	public static final String STATUS_ACTIVE = 'active';
	/**
	 * Product trial has expired.
	 */
	public static final String STATUS_EXPIRED = 'expired';

	/**
	 * The product name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The product status on the account.
	 */
	@AuraEnabled
	public String status { get; private set; }
	/**
	 * Whether this product is a trial.
	 */
	@AuraEnabled
	public Boolean isTrial { get; private set; }
	/**
	 * If the product is a trial, when it expires.
	 */
	@AuraEnabled
	public Date trialExpires { get; private set; }
	/**
	 * If the product is a trial, whether it has expired.
	 */
	@AuraEnabled
	public Boolean isExpired {
		get {
			return this.isTrial
				&& this.trialExpires < Date.today();
		}
	}
	/**
	 * If the product is a trial, how many days until it expires.
	 */
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

	public static String getRoleLabel(final String role) {
		switch on (role == null ? '' : role.toLowerCase()) {
			when 'administrator' {
				return Label.Administrator;
			} when 'user' {
				return Label.User;
			} when 'viewer' {
				return Label.Viewer;
			} when 'negotiator' {
				return Label.Negotiator;
			} when 'generator' {
				return Label.Generator;
			} when 'sender' {
				return Label.Sender;
			} when else {
				return role;
			}
		}
	}

	/**
	 * Represents a product role.
	 */
	public class Role {
		/**
		 * The DocuSign ID of the role.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		/**
		 * The product of the role.
		 */
		@AuraEnabled
		public String product { get; private set; }
		/**
		 * The name of the role.
		 */
		@AuraEnabled
		public String role { get; private set; }
		/**
		 * The localized label of the role, if it exists.
		 */
		@AuraEnabled
		public String label { get; private set; }
		/**
		 * Whether the role is an administrator role.
		 */
		@AuraEnabled
		public Boolean isAdministrator { get; private set; }

		/**
		 * Constructs a product role.
		 *
		 * @param id The DocuSign ID of the role.
		 * @param product The product of the role.
		 * @param role The name of the role.
		 * @param label The localized label of the role, if it exists.
		 * @param isAdministrator Whether the role is an administrator role.
		 */
		public Role(
			final UUID id,
			final String product,
			final String role,
			final String label,
			final Boolean isAdministrator) {

			this.id = id;
			this.product = product;
			this.role = role;
			this.label = label;
			this.isAdministrator = isAdministrator;
		}
	}

	public static Boolean isValidProduct(final String product) {
		return String.isNotBlank(product)
			&& VALID_PRODUCT_ROLES.containsKey(product.toLowerCase());
	}

	public static Boolean isValidRole(
		final String product,
		final String role) {

		return isValidProduct(product)
			&& String.isNotBlank(role)
			&& VALID_PRODUCT_ROLES.get(product.toLowerCase()).contains(role.toLowerCase());
	}

	public static Boolean isValidRole(final Product.Role role) {
		return role != null
			&& UUID.isNotEmpty(role.id)
			&& isValidRole(role.product, role.role);
	}
}
