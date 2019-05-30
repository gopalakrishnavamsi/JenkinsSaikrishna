/**
 * Representation of the result of a login attempt.
 */
public class LoginInformation {
	/**
	 * Status where a login was successful and mapped to a single valid DocuSign account.
	 */
	public static final String STATUS_SUCCESS = 'Success';
	/**
	 * Status where a login was successful, but maps to multiple valid DocuSign accounts.
	 */
	public static final String STATUS_SELECT_ACCOUNT = 'SelectAccount';
	/**
	 * Status where a login failed because the DocuSign username or password was invalid or the user did not grant
	 * consent.
	 */
	public static final String STATUS_FAILURE = 'Failure';

	/**
	 * The Salesforce OAuth event target.
	 */
	@AuraEnabled
	public String target { get; private set; }
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
	/**
	 * A message associated with the login attempt, e.g. an error message.
	 */
	@AuraEnabled
	public String message { get; private set; }

	public LoginInformation(
		final String status,
		final String message,
		final String target) {

		this.status = status;
		this.message = message;
		this.target = target;
	}

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
			this.status = STATUS_FAILURE;
			this.message = Label.InvalidUsernameOrPassword;
		} else if (Collection.size(this.accounts) == 1) {
			this.status = STATUS_SUCCESS;
		} else {
			this.status = STATUS_SELECT_ACCOUNT;
			this.message = Label.MultipleAccountsMessage;
		}
	}

	public LoginInformation withTarget(final String target) {
		this.target = target;
		return this;
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
		 * The DocuSign ESignature API base URL string.
		 */
		@AuraEnabled
		public String eSignatureBaseUrl { get; private set; }
		/**
		 * Whether this is the default DocuSign account linked to the user.
		 */
		@AuraEnabled
		public Boolean isDefault { get; private set; }

		public Account(
			final UUID id,
			final Long accountNumber,
			final String name,
			final String eSignatureBaseUrl,
			final Boolean isDefault) {

			this.id = id;
			this.accountNumber = accountNumber;
			this.name = name;
			this.eSignatureBaseUrl = eSignatureBaseUrl;
			this.isDefault = isDefault;
		}
	}
}
