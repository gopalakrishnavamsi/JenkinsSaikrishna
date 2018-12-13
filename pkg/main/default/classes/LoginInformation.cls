/**
 * Representation of the result of a login attempt.
 */
public class LoginInformation {
	/**
	 * Login statuses:
	 * <ul>
	 *     <li><code>Success</code>: Login was successful and mapped to a single valid DocuSign account.</li>
	 *     <li><code>Failure</code>: Invalid DocuSign username or password.</li>
	 *     <li><code>SelectAccount</code>: Login was successful, but maps to mulitple valid DocuSign accounts.</li>
	 * </ul>
	 */
	public enum LoginStatus {
		Success, Failure, SelectAccount
	}

	/**
	 * The DocuSign user ID.
	 */
	@AuraEnabled
	public UUID id { get; private set; }
	/**
	 * The user's name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The user's email address.
	 */
	@AuraEnabled
	public String email { get; private set; }
	/**
	 * Valid DocuSign accounts from which to choose. Populated if the <code>status</code> is
	 * <code>SelectAccount</code>.
	 */
	@AuraEnabled
	public List<LoginInformation.Account> accounts { get; private set; }
	/**
	 * The status of the login attempt.
	 */
	@AuraEnabled
	public String status { get; private set; }

	public LoginInformation(
		final UUID id,
		final String name,
		final String email,
		final List<LoginInformation.Account> accounts) {

		this.id = id;
		this.name = name;
		this.email = email;
		this.accounts = accounts == null ? new List<LoginInformation.Account>() : accounts;
		if (Collection.isEmpty(this.accounts)) {
			this.status = LoginStatus.Failure.name();
		} else if (Collection.size(this.accounts) == 1) {
			this.status = LoginStatus.Success.name();
		} else {
			this.status = LoginStatus.SelectAccount.name();
		}
	}

	/**
	 * A DocuSign account.
	 */
	public class Account {
		/**
		 * The DocuSign account ID.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		/**
		 * The DocuSign account number.
		 */
		@AuraEnabled
		public Long accountNumber { get; private set; }
		/**
		 * The DocuSign account name.
		 */
		@AuraEnabled
		public String name { get; private set; }
		/**
		 * The DocuSign API base URL string.
		 */
		@AuraEnabled
		public String baseUrl { get; private set; }
		/**
		 * Whether this is the default DocuSign account linked to the user.
		 */
		@AuraEnabled
		public Boolean isDefault { get; private set; }
		/**
		 * The account display string.
		 */
		@AuraEnabled
		public String display {
			get {
				return String.format(Label.AccountDisplay_2, new List<String> {
					this.name, String.valueOf(this.accountNumber)
				});
			}
		}

		public Account(
			final UUID id,
			final Long accountNumber,
			final String name,
			final String baseUrl,
			final Boolean isDefault) {

			this.id = id;
			this.accountNumber = accountNumber;
			this.name = name;
			this.baseUrl = baseUrl;
			this.isDefault = isDefault;
		}
	}
}
