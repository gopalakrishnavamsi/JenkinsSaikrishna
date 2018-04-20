public class Account {

	public UUID id { get; private set; }
	public String name { get; private set; }
	public Plan plan { get; private set; }
	public Billing billing { get; private set; }
	public ConnectPermission connect { get; private set; }
	public transient Environment environment { get; private set; }

	public Account(final UUID id, final String name, final Plan plan, final Billing billing,
		final ConnectPermission connect, final Environment environment) {

		this.id = id;
		this.name = name;
		this.plan = plan;
		this.billing = billing;
		this.connect = connect == null ? ConnectPermission.None : connect;
		this.environment = environment;
	}

	public Account withPlanId(final UUID planId) {
		this.plan = this.plan.withId(planId);
		return this;
	}

	public class Plan {

		public UUID id { get; private set; }
		public String name { get; private set; }
		public Date startDate { get; private set; }
		public String startDateFormatted { get; private set; }
		public Date endDate { get; private set; }
		public String endDateFormatted { get; private set; }

		public Plan(final UUID id, final String name, final Date startDate, final Date endDate) {
			this.id = id;
			this.name = name;
			this.startDate = startDate;
			this.startDateFormatted = startDate != null ? startDate.format() : '';
			this.endDate = endDate;
			this.endDateFormatted = endDate != null ? endDate.format() : '';
		}

		public Plan withId(final UUID id) {
			this.id = id;
			return this;
		}
	}

	public class Billing {

		public Date startDate { get; private set; }
		public String startDateFormatted { get; private set; }
		public Date endDate { get; private set; }
		public String endDateFormatted { get; private set; }

		public Billing(final Date startDate, final Date endDate) {
			this.startDate = startDate;
			this.startDateFormatted = startDate != null ? startDate.format() : '';
			this.endDate = endDate;
			this.endDateFormatted = endDate != null ? endDate.format() : '';
		}
	}

	public enum ConnectPermission {
		None, Full, SendOnly
	}

	public class Address {
		public String address1 { get; private set; }
		public String address2 { get; private set; }
		public String city { get; private set; }
		public String region { get; private set; }
		public String postalCode { get; private set; }
		public String country { get; private set; }
		public String phone { get; private set; }

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

	public enum UserStatus {
		Unknown, PendingActivation, Active, Closed
	}

	public class User {

		public UUID id { get; private set; }
		public String username { get; private set; }
		public String email { get; private set; }
		public String firstName { get; private set; }
		public String lastName { get; private set; }
		public String name {
			get {
				return StringUtils.mkName(firstName, lastName);
			}
		}
		public String apiPassword { get; private set; }
		public UserStatus status { get; private set; }
		public Boolean canManageAccount { get; private set; }
		public Boolean canSendEnvelope { get; private set; }
		public Id sourceId { get; private set; }
		public APIError error { get; private set; }
		public Boolean hasError { get; private set; }

		public User(final UUID id) {
			this(id, null, null, null, null, null, UserStatus.Unknown, false, true, null, APIError.none);
		}

		public User(final String username, final String email, final String firstName, final String lastName,
			final Boolean canManageAccount) {

			this(null, username, email, firstName, lastName, null, UserStatus.Unknown, canManageAccount,
				true, null, APIError.none);
		}

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
			this.hasError = this.error != APIError.none;
		}

		public User withError(final APIError error) {
			this.error = error;
			return this;
		}
	}

	public class TrialUser {

		public String email { get; private set; }
		public String firstName { get; private set; }
		public String lastName { get; private set; }
		public String name {
			get {
				return StringUtils.mkName(firstName, lastName);
			}
		}

		public TrialUser(final String email, final String firstName, final String lastName) {
			this.email = email;
			this.firstName = firstName;
			this.lastName = lastName;
		}
	}

	public class Trial {

		public String company { get; private set; }
		public TrialUser user { get; private set; }
		public Address address { get; private set; }
		public Boolean termsAccepted { get; private set; }

		public Trial(final String company, final TrialUser user, final Address address, final Boolean termsAccepted) {
			this.company = company;
			this.user = user;
			this.address = address;
			this.termsAccepted = termsAccepted;
		}
	}

	public class Membership {

		public Long accountId { get; private set; }
		public UUID accountUUID { get; private set; }
		public String name { get; private set; }
		public UUID userId { get; private set; }
		public transient String apiPassword { get; private set; }
		public transient Url baseUrl { get; private set; }
		public Map<String, String> settings { get; private set; }

		public Membership(final Long accountId, final UUID accountUUID, final String name, final UUID userId,
			final Url baseUrl, final String apiPassword) {

			this(accountId, accountUUID, name, userId, baseUrl, null, apiPassword);
		}

		public Membership(final Long accountId, final UUID accountUUID, final String name, final UUID userId,
			final Url baseUrl, final Map<String, String> settings) {

			this(accountId, accountUUID, name, userId, baseUrl, settings, null);
		}

		public Membership(final Long accountId, final UUID accountUUID, final String name, final UUID userId,
			final Url baseUrl, final Map<String, String> settings, String apiPassword) {

			this.accountId = accountId;
			this.accountUUID = accountUUID;
			this.name = name;
			this.userId = userId;
			this.baseUrl = baseUrl;
			this.settings = settings == null ? new Map<String, String>() : settings;
			this.apiPassword = apiPassword;
		}

		public Membership withSettings(final Map<String, String> settings) {
			return new Membership(accountId, accountUUID, name, userId, baseUrl, settings);
		}

		public Boolean getFlag(final String key) {
			Boolean result = false;
			if (String.isNotBlank(key)) {
				final String value = settings.get(key);
				result = String.isNotBlank(value) && Boolean.valueOf(value);
			}
			return result;
		}

		public Membership scrub() {
			this.apiPassword = null;
			return this;
		}
	}

	public class Memberships {

		public List<Membership> accounts { get; private set; }
		public transient String apiPassword { get; private set; }

		public Memberships(final List<Membership> accounts, final String apiPassword) {
			this.accounts = accounts;
			this.apiPassword = apiPassword;
		}
	}

	public class Credentials {
		public Long accountId { get; private set; }
		public UUID accountUUID { get; private set; }
		public String apiPassword { get; private set; }

		public Credentials(final Long accountId, final UUID accountUUID, final String apiPassword) {
			this.accountId = accountId;
			this.accountUUID = accountUUID;
			this.apiPassword = apiPassword;
		}
	}
}
