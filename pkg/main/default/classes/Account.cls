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
	 * The DocuSign account status.
	 */
	@AuraEnabled
	public String status { get; private set; }
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
	 * Read-only property describing whether the account is a trial account.
	 */
	public Boolean isTrial {
		get {
			return this.billing != null
				&& this.plan != null
				&& this.plan.id == DocuSign.TRIAL_PLAN_ID;
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
	 * @param accountNumber The DocuSign account number.
	 * @param name The DocuSign account name.
	 * @param status The DocuSign account status.
	 * @param plan The DocuSign account plan.
	 * @param billing The DocuSign account billing information.
	 * @param connect The DocuSign Connect permissions for the account.
	 */
	public Account(
		final UUID id,
		final Long accountNumber,
		final String name,
		final String status,
		final Plan plan,
		final Billing billing,
		final ConnectPermission connect) {

		this.id = id;
		this.accountNumber = accountNumber;
		this.name = name;
		this.status = status;
		this.plan = plan;
		this.billing = billing;
		this.connect = connect == null ? ConnectPermission.None : connect;
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
	 * Representation of the status of a DocuSign trial account.
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
	 * User must respond to activation email.
	 */
	public static final String USER_STATUS_PENDING = 'Pending';
	/**
	 * User is an active member of the account.
	 */
	public static final String USER_STATUS_ACTIVE = 'Active';
	/**
	 * The user account membership has been closed.
	 */
	public static final String USER_STATUS_INACTIVE = 'Inactive';

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
		 * The Salesforce ID of the user.
		 */
		@AuraEnabled
		public Id sourceId { get; private set; }
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
		 * The user status.
		 */
		@AuraEnabled
		public String status { get; private set; }
		/**
		 * Date when the user was provisioned.
		 */
		@AuraEnabled
		public Date provisioned { get; private set; }
		/**
		 * Whether or not the user is a DocuSign account administrator.
		 */
		@AuraEnabled
		public Boolean canManageAccount { get; private set; }
		/**
		 * The user's Salesforce profile.
		 */
		@AuraEnabled
		public String profile { get; private set; }
		/**
		 * The user's assigned application roles.
		 */
		@AuraEnabled
		public Map<String, List<String>> roles { get; private set; }
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
		 * Constructs a DocuSign user from a source ID and username.
		 *
		 * @param id The DocuSign user ID.
		 * @param sourceId The Salesforce user ID.
		 */
		public User(
			final UUID id,
			final Id sourceId) {

			this(
				id,
				sourceId,
				null,
				null,
				null,
				null,
				null,
				false,
				null,
				null,
				APIError.none);
		}

		/**
		 * Constructs a DocuSign user.
		 *
		 * @param sourceId The salesforce user ID.
		 * @param email The user's email.
		 * @param firstName The user's first name.
		 * @param lastName The user's last name.
		 * @param canManageAccount Whether or not the user is an administrator for the DocuSign account.
		 */
		public User(
			final Id sourceId,
			final String email,
			final String firstName,
			final String lastName,
			final Boolean canManageAccount) {

			this(
				null,
				sourceId,
				email,
				firstName,
				lastName,
				null,
				null,
				canManageAccount,
				null,
				null,
				null);
		}

		/**
		 * Constructs a DocuSign user.
		 *
		 * @param id The DocuSign user ID.
		 * @param sourceId The Salesforce ID of the user.
		 * @param email The user's email.
		 * @param firstName The user's first name.
		 * @param lastName The user's last name.
		 * @param status The user's status.
		 * @param provisioned Date when the user was provisioned.
		 * @param canManageAccount Whether or not the user is an administrator for the DocuSign account.
		 * @param profile The user's Salesforce profile name.
		 * @param roles The user's assigned application roles.
		 * @param error The error returned by the API for bulk add or remove account member operations.
		 */
		public User(
			final UUID id,
			final Id sourceId,
			final String email,
			final String firstName,
			final String lastName,
			final String status,
			final Date provisioned,
			final Boolean canManageAccount,
			final String profile,
			final Map<String, List<String>> roles,
			final APIError error) {

			this.id = id;
			this.sourceId = sourceId;
			this.email = email;
			this.firstName = firstName;
			this.lastName = lastName;
			this.status = status;
			this.provisioned = provisioned;
			this.canManageAccount = canManageAccount;
			this.profile = profile;
			this.roles = roles == null ? new Map<String, List<String>>() : roles;
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
		 * Updates a user's <code>roles</code> property.
		 *
		 * @param role The new application roles.
		 *
		 * @return The user with an updated <code>roles</code> property.
		 */
		public User withRoles(final Map<String, List<String>> roles) {
			this.roles = roles == null ? new Map<String, List<String>>() : roles;
			return this;
		}
	}
}
