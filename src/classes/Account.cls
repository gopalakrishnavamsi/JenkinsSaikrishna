/**
 * Representation of a DocuSign account.
 */
public class Account {
	/**
	 * The DocuSign account ID.
	 */
	@AuraEnabled
	public UUID id { get; private set; }
	/**
	 * The DocuSign account name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The DocuSign account plan.
	 */
	@AuraEnabled
	public Plan plan { get; private set; }
	/**
	 * The DocuSign account billing information.
	 */
	@AuraEnabled
	public Billing billing { get; private set; }
	/**
	 * The DocuSign Connect permissions for the account.
	 */
	@AuraEnabled
	public ConnectPermission connect { get; private set; }
	/**
	 * The DocuSign environment.
	 */
	public transient Environment environment { get; private set; }
	/**
	 * Read-only property describing whether the account is a trial account.
	 */
	public Boolean isTrial {
		get {
			return this.billing != null
				&& this.plan != null
				&& this.environment != null
				&& this.plan.id == this.environment.trialPlanId;
		}
	}
	/**
	 * The status of the DocuSign account trial.
	 */
	@AuraEnabled
	public TrialStatus trialStatus { get; private set; }

	/**
	 * Constructs a DocuSign account.
	 *
	 * @param id The DocuSign account ID.
	 * @param name The DocuSign account name.
	 * @param plan The DocuSign account plan.
	 * @param billing The DocuSign account billing information.
	 * @param connect The DocuSign Connect permissions for the account.
	 * @param environment The DocuSign environment.
	 */
	public Account(final UUID id, final String name, final Plan plan, final Billing billing,
		final ConnectPermission connect, final Environment environment) {

		this.id = id;
		this.name = name;
		this.plan = plan;
		this.billing = billing;
		this.connect = connect == null ? ConnectPermission.None : connect;
		this.environment = environment;
	}

	/**
	 * Updates a DocuSign account's <code>plan</code>.
	 *
	 * @param planId The DocuSign account plan ID.
	 *
	 * @return The DocuSign account with updated <code>plan</code>.
	 */
	public Account withPlanId(final UUID planId) {
		this.plan = this.plan.withId(planId);
		return this;
	}

	/**
	 * Updates a DocuSign account's <code>trialStatus</code>.
	 *
	 * @param trialStatus The DocuSign account trial status.
	 *
	 * @return The DocuSign account with updated <code>trialStatus</code>.
	 */
	public Account withTrialStatus(final TrialStatus trialStatus) {
		this.trialStatus = trialStatus;
		return this;
	}

	/**
	 * Represention of the status of a DocuSign trial account.
	 */
	public class TrialStatus {
		/**
		 * Whether or not the trial has expired.
		 */
		@AuraEnabled
		public Boolean isExpired { get; private set; }
		/**
		 * The trial status message. This may be a friendly warning to upgrade soon.
		 */
		@AuraEnabled
		public String message { get; private set; }

		/**
		 * Constructs a DocuSign account trial status.
		 *
		 * @param isExpired Whether or not the trial has expired.
		 * @param message The trial status message.
		 */
		public TrialStatus(final Boolean isExpired, final String message) {
			this.isExpired = isExpired;
			this.message = message;
		}
	}

	/**
	 * Representation of a DocuSign account plan.
	 */
	public class Plan {
		/**
		 * The plan ID.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		/**
		 * The plan name.
		 */
		@AuraEnabled
		public String name { get; private set; }
		/**
		 * The plan start date.
		 */
		@AuraEnabled
		public Date startDate { get; private set; }
		/**
		 * The plan end date.
		 */
		@AuraEnabled
		public Date endDate { get; private set; }

		/**
		 * Constructs a DocuSign account plan.
		 *
		 * @param id The plan ID.
		 * @param name The plan name.
		 * @param startDate The plan start date.
		 * @param endDate The plan end date.
		 */
		public Plan(final UUID id, final String name, final Date startDate, final Date endDate) {
			this.id = id;
			this.name = name;
			this.startDate = startDate;
			this.endDate = endDate;
		}

		/**
		 * Updates a DocuSign account plan's <code>id</code>.
		 *
		 * @param id The new plan ID.
		 *
		 * @return The DocuSign account plan with updated <code>id</code>.
		 */
		public Plan withId(final UUID id) {
			this.id = id;
			return this;
		}
	}

	/**
	 * Representation of DocuSign account billing information.
	 */
	public class Billing {
		/**
		 * The billing start date.
		 */
		@AuraEnabled
		public Date startDate { get; private set; }
		/**
		 * The billing end date.
		 */
		@AuraEnabled
		public Date endDate { get; private set; }

		/**
		 * Constructs DocuSign account billing information.
		 *
		 * @param startDate The billing start date.
		 * @param endDate The billing end date.
		 */
		public Billing(final Date startDate, final Date endDate) {
			this.startDate = startDate;
			this.endDate = endDate;
		}
	}

	/**
	 * Possible DocuSign Connect permissions:
	 * <ul>
	 *     <li><code>None</code></li>
	 *     <li><code>Full</code></li>
	 *     <li><code>SendOnly</code></li>
	 * </ul>
	 */
	public enum ConnectPermission {
		None, Full, SendOnly
	}

	/**
	 * Representation of an address used for creating DocuSign trial accounts.
	 */
	public class Address {
		/**
		 * Line 1 of the address, typically the street and number.
		 */
		@AuraEnabled
		public String address1 { get; private set; }
		/**
		 * Line 2 of the address (e.g. suite, building, etc.).
		 */
		@AuraEnabled
		public String address2 { get; private set; }
		/**
		 * The city.
		 */
		@AuraEnabled
		public String city { get; private set; }
		/**
		 * The state, province, or administrative region.
		 */
		@AuraEnabled
		public String region { get; private set; }
		/**
		 * The ZIP or postal code.
		 */
		@AuraEnabled
		public String postalCode { get; private set; }
		/**
		 * The country.
		 */
		@AuraEnabled
		public String country { get; private set; }
		/**
		 * The phone number.
		 */
		@AuraEnabled
		public String phone { get; private set; }

		/**
		 * Constructs an address.
		 *
		 * @param address1 Line 1 of the address.
		 * @param address2 Line 2 of the address.
		 * @param city The city.
		 * @param region The state, province, or adminsistrative region.
		 * @param postalCode The ZIP or postal code.
		 * @param country The country.
		 * @param phone The phone number.
		 */
		public Address(final String address1, final String address2, final String city, final String region,
			final String postalCode, final String country, final String phone) {

			this.address1 = address1;
			this.address2 = address2;
			this.city = city;
			this.region = region;
			this.postalCode = postalCode;
			this.country = country;
			this.phone = phone;
		}
	}

	/**
	 * Possible user statuses:
	 * <ul>
	 *     <li><code>Unknown</code>: Could not determine current status.</li>
	 *     <li><code>PendingActivation</code>: User must activate membership via email.</li>
	 *     <li><code>Active</code>: User is active within the account. Users with this status are able to use
	 *     DocuSign for Salesforce</li>
	 *     <li><code>Closed</code>: User account membership has been closed.</li>
	 * </ul>
	 */
	public enum UserStatus {
		Unknown, PendingActivation, Active, Closed
	}

	/**
	 * Representation of a DocuSign account user or member.
	 */
	public class User {
		/**
		 * The DocuSign user ID.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		/**
		 * The DocuSign username.
		 */
		@AuraEnabled
		public String username { get; private set; }
		/**
		 * The DocuSign user email.
		 */
		@AuraEnabled
		public String email { get; private set; }
		/**
		 * The DocuSign user first name.
		 */
		@AuraEnabled
		public String firstName { get; private set; }
		/**
		 * The DocuSign user last name.
		 */
		@AuraEnabled
		public String lastName { get; private set; }
		/**
		 * Read-only DocuSign user name based on <code>firstName</code> and <code>lastName<code>.
		 */
		@AuraEnabled
		public String name {
			get {
				return StringUtils.mkName(firstName, lastName);
			}
		}
		/**
		 * The API password for the user. This is never returned through public methods.
		 */
		public transient String apiPassword { get; private set; }
		/**
		 * The user status.
		 */
		@AuraEnabled
		public UserStatus status { get; private set; }
		/**
		 * Whether or not the user is a DocuSign account administrator.
		 */
		@AuraEnabled
		public Boolean canManageAccount { get; private set; }
		/**
		 * Whether or not the user can send DocuSign envelopes.
		 */
		public Boolean canSendEnvelope { get; private set; }
		/**
		 * The Salesforce ID of the user.
		 */
		@AuraEnabled
		public Id sourceId { get; private set; }
		/**
		 * The error returned by the API for bulk add or remove account member operations.
		 */
		@AuraEnabled
		public APIError error { get; private set; }
		/**
		 * Read-only property indicating whether there was an error with an associated API operation.
		 */
		@AuraEnabled
		public Boolean hasError {
			get {
				return this.error != null && this.error != APIError.none;
			}
		}

		/**
		 * Constructs a DocuSign user from a DocuSign user ID.
		 *
		 * @param id The DocuSign user ID.
		 */
		public User(final UUID id) {
			this(id, null, null, null, null, null, UserStatus.Unknown, false, true, null, APIError.none);
		}

		/**
		 * Constructs a DocuSign user.
		 *
		 * @param username The username.
		 * @param email The user's email.
		 * @param firstName The user's first name.
		 * @param lastName The user's last name.
		 * @param canManageAccount Whether or not the user is an administrator for the DocuSign account.
		 */
		public User(final String username, final String email, final String firstName, final String lastName,
			final Boolean canManageAccount) {

			this(null, username, email, firstName, lastName, null, UserStatus.Unknown, canManageAccount,
				true, null, APIError.none);
		}

		/**
		 * Constructs a DocuSign user.
		 *
		 * @param id The DocuSign user ID.
		 * @param username The username.
		 * @param email The user's email.
		 * @param firstName The user's first name.
		 * @param lastName The user's last name.
		 * @param apiPassword The user's API password.
		 * @param status The user's status.
		 * @param canManageAccount Whether or not the user is an administrator for the DocuSign account.
		 * @param canSendEnvelope Whether or not the user can send DocuSign envelopes.
		 * @param sourceId The Salesforce ID of the user.
		 * @param error The error returned by the API for bulk add or remove account member operations.
		 */
		public User(final UUID id, final String username, final String email, final String firstName, final String lastName,
			final String apiPassword, final UserStatus status, final Boolean canManageAccount,
			final Boolean canSendEnvelope, final Id sourceId, final APIError error) {

			this.id = id;
			this.username = username;
			this.email = email;
			this.firstName = firstName;
			this.lastName = lastName;
			this.apiPassword = apiPassword;
			this.status = status;
			this.canManageAccount = canManageAccount;
			this.canSendEnvelope = canSendEnvelope;
			this.sourceId = sourceId;
			this.error = error == null ? APIError.none : error;
		}

		/**
		 * Updates a user's <code>error</code> property.
		 *
		 * @param error The new API error.
		 *
		 * @return The user with an updated <code>error</code> property.
		 */
		public User withError(final APIError error) {
			this.error = error;
			return this;
		}

		/**
		 * Updates a user's <code>sourceId</code> property.
		 *
		 * @param sourceId The Salesforce ID of the user.
		 *
		 * @return The user with an updated <code>sourceId</code> property.
		 */
		public User withSourceId(final Id sourceId) {
			this.sourceId = sourceId;
			return this;
		}
	}

	/**
	 * Representation of a DocuSign trial account user or member.
	 */
	public class TrialUser {
		/**
		 * The user's email.
		 */
		@AuraEnabled
		public String email { get; private set; }
		/**
		 * The user's first name.
		 */
		@AuraEnabled
		public String firstName { get; private set; }
		/**
		 * The user's last name.
		 */
		@AuraEnabled
		public String lastName { get; private set; }
		/**
		 * Read-only name of the user based on <code>firstName</code> and <code>lastName</code>.
		 */
		@AuraEnabled
		public String name {
			get {
				return StringUtils.mkName(firstName, lastName);
			}
		}

		/**
		 * Constructs a DocuSign trial account user.
		 *
		 * @param email The user's email.
		 * @param firstName The user's first name.
		 * @param lastName The user's last name.
		 */
		public TrialUser(final String email, final String firstName, final String lastName) {
			this.email = email;
			this.firstName = firstName;
			this.lastName = lastName;
		}
	}

	/**
	 * Representation of a DocuSign trial account.
	 */
	public class Trial {
		/**
		 * The company of the trial account.
		 */
		@AuraEnabled
		public String company { get; private set; }
		/**
		 * The user of the trial account.
		 */
		@AuraEnabled
		public TrialUser user { get; private set; }
		/**
		 * The address of the trial account.
		 */
		@AuraEnabled
		public Address address { get; private set; }
		/**
		 * Whether or not DocuSign trial account terms and conditions have been accepted.
		 */
		@AuraEnabled
		public Boolean termsAccepted { get; private set; }

		/**
		 * Constructs a trial account.
		 *
		 * @param company The trial account company.
		 * @param user The trial account user.
		 * @param address The trial account address.
		 * @param termsAccepted Whether or not DocuSign trial account terms and conditions have been accepted.
		 */
		public Trial(final String company, final TrialUser user, final Address address, final Boolean termsAccepted) {
			this.company = company;
			this.user = user;
			this.address = address;
			this.termsAccepted = termsAccepted;
		}

		/**
		 * Accepts DocuSign trial account terms and conditions.
		 *
		 * @return The trial account with <code>termsAccepted</code> set to <code>true</code>.
		 */
		public Trial acceptTermsAndConditions() {
			this.termsAccepted = true;
			return this;
		}
	}

	/**
	 * Representation of a DocuSign account membership.
	 */
	public class Membership {
		/**
		 * The DocuSign account number.
		 */
		@AuraEnabled
		public Long accountNumber { get; private set; }
		/**
		 * The DocuSign account ID.
		 */
		@AuraEnabled
		public UUID accountId { get; private set; }
		/**
		 * The DocuSign account name.
		 */
		@AuraEnabled
		public String name { get; private set; }
		/**
		 * The DocuSign user ID within an account.
		 */
		@AuraEnabled
		public UUID userId { get; private set; }
		/**
		 * The DocuSign API password. This is never returned by public methods.
		 */
		public transient String apiPassword { get; private set; }
		/**
		 * The DocuSign API base Url.
		 */
		public transient Url baseUrl { get; private set; }
		/**
		 * The DocuSign account settings.
		 */
		public Map<String, String> settings { get; private set; }

		/**
		 * Constructs a DocuSign account membership.
		 *
		 * @param accountNumber The DocuSign account number.
		 * @param accountId The DocuSign account ID.
		 * @param name The DocuSign account name.
		 * @param userId The DocuSign user ID in the context of an account.
		 * @param baseUrl The DocuSign API base Url.
		 * @param apiPassword The DocuSign API password.
		 */
		public Membership(final Long accountNumber, final UUID accountId, final String name, final UUID userId,
			final Url baseUrl, final String apiPassword) {

			this(accountNumber, accountId, name, userId, baseUrl, null, apiPassword);
		}

		/**
		 * Constructs a DocuSign account membership.
		 *
		 * @param accountNumber The DocuSign account number.
		 * @param accountId The DocuSign account ID.
		 * @param name The DocuSign account name.
		 * @param userId The DocuSign user ID in the context of an account.
		 * @param baseUrl The DocuSign API base Url.
		 * @param settings The DocuSign account settings.
		 */
		public Membership(final Long accountNumber, final UUID accountId, final String name, final UUID userId,
			final Url baseUrl, final Map<String, String> settings) {

			this(accountNumber, accountId, name, userId, baseUrl, settings, null);
		}

		/**
		 * Constructs a DocuSign account membership.
		 *
		 * @param accountNumber The DocuSign account number.
		 * @param accountId The DocuSign account ID.
		 * @param name The DocuSign account name.
		 * @param userId The DocuSign user ID in the context of an account.
		 * @param baseUrl The DocuSign API base Url.
		 * @param settings The DocuSign account settings.
		 * @param apiPassword The DocuSign API password.
		 */
		public Membership(final Long accountNumber, final UUID accountId, final String name, final UUID userId,
			final Url baseUrl, final Map<String, String> settings, String apiPassword) {

			this.accountNumber = accountNumber;
			this.accountId = accountId;
			this.name = name;
			this.userId = userId;
			this.baseUrl = baseUrl;
			this.settings = settings == null ? new Map<String, String>() : settings;
			this.apiPassword = apiPassword;
		}

		/**
		 * Copies the DocuSign account membership with an updated <code>settings</code> property.
		 *
		 * @param settings The copied account membership.
		 *
		 * @return A copy of the DocuSign account membership with updated <code>settings</code>.
		 */
		public Membership withSettings(final Map<String, String> settings) {
			return new Membership(this.accountNumber, this.accountId, this.name, this.userId, this.baseUrl, settings,
				this.apiPassword);
		}

		/**
		 * Gets a boolean value for a given account settings key.
		 *
		 * @param key The account settings key.
		 *
		 * @return <code>true</code> if the setting exists and is set to 'true' or '1', <code>false</code> otherwise.
		 */
		public Boolean getFlag(final String key) {
			Boolean result = false;
			if (String.isNotBlank(key)) {
				result = StringUtils.parseBoolean(settings.get(key), false);
			}
			return result;
		}

		/**
		 * Removes sensitive information from the account membership.
		 *
		 * @return The scrubbed account membership.
		 */
		public Membership scrub() {
			this.apiPassword = null;
			return this;
		}
	}

	/**
	 * Representation of DocuSign account credentials.
	 */
	public class Credentials {
		/**
		 * The DocuSign account number.
		 */
		public Long accountNumber { get; private set; }
		/**
		 * The DocuSign account ID.
		 */
		public UUID accountId { get; private set; }
		/**
		 * The DocuSign API password. This is never returned by public methods.
		 */
		public transient String apiPassword { get; private set; }

		/**
		 * Constructs DocuSign account credentials.
		 *
		 * @param accountNumber The DocuSign account number.
		 * @param accountId The DocuSign account ID.
		 * @param apiPassword The DocuSign API password.
		 */
		public Credentials(final Long accountNumber, final UUID accountId, final String apiPassword) {
			this.accountNumber = accountNumber;
			this.accountId = accountId;
			this.apiPassword = apiPassword;
		}
	}
}
