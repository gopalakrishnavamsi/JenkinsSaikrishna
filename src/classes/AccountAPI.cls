public with sharing class AccountAPI extends DocuSignAPI {

	private static AccountAPI self = null;
	private static final String SUCCESS = 'SUCCESS';
	private static final String USER_ALREADY_EXISTS_IN_ACCOUNT = 'USER_ALREADY_EXISTS_IN_ACCOUNT';
	private static final String USER_DOES_NOT_EXIST = 'USER_DOES_NOT_EXIST_IN_SYSTEM';
	private static final String INVALID_USERID = 'INVALID_USERID';

	private static Organization__mdt secureSettings = null;
	private static List<CustomField> accountCustomFields = null;

	private final String username;
	private final String password;
	private Account account = null;
	private final Url apiBaseUrl;

	@TestVisible
	private AccountAPI(final Credentials apiCredentials) {
		super(apiCredentials);

		this.apiBaseUrl = new Url(this.baseUrl, '/restapi/v2/');
		if (apiCredentials != null) {
			this.username = apiCredentials.username;
			this.password = apiCredentials.password;
		}
	}

	public static AccountAPI getInstance() {
		if (self == null) {
			self = new AccountAPI(Credentials.getInstance());
		}
		return self;
	}

	public static AccountAPI getInstance(final Environment environment) {
		return getInstance(environment, null, null);
	}

	public static AccountAPI getInstance(final Environment environment, final String username, final String password) {
		return new AccountAPI(Credentials.getInstance(environment, username, password));
	}

	private static Organization__mdt getSecureSettings() {
		if (secureSettings == null) {
			secureSettings = [
				SELECT DistributorCode__c, DistributorPassword__c
				FROM Organization__mdt
				WHERE DeveloperName = 'SecureSettings'
				LIMIT 1
			];
		}
		return secureSettings;
	}

	@TestVisible
	override protected APIError getError(final HttpResponse response) {
		APIError e = super.getError(response);
		if (e != APIError.none && e instanceof DocuSignAPI.Error) {
			DocuSignAPI.Error dse = (DocuSignAPI.Error)e;
			if (dse.docuSignCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, dse.description);
			} else if (dse.docuSignCode == USER_DOES_NOT_EXIST || dse.docuSignCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, dse.description);
			}
		}
		return e;
	}

	// Serialization objects for createAccount
	private class Address {
		private final String address1;
		private final String address2;
		private final String city;
		private final String state;
		private final String postalCode;
		private final String phone;
		private final String country;

		public Address(final Account.Address a) {
			if (a != null) {
				this.address1 = a.address1;
				this.address2 = a.address2;
				this.city = a.city;
				this.state = a.region;
				this.postalCode = a.postalCode;
				this.phone = a.phone;
				this.country = a.country;
			}
		}
	}

	private class Referral {
		private final String referralCode;
		private final String referrerName;
		private final String promoCode;

		public Referral(final String referralCode, final String referrerName, final String promoCode) {
			this.referralCode = referralCode;
			this.referrerName = referrerName;
			this.promoCode = promoCode;
		}
	}

	private class Plan {
		private final String planId;

		public Plan(final UUID planId) {
			this.planId = UUID.toString(planId);
		}
	}

	private class TrialAccount {
		private final String accountName;
		private final APIUser initialUser;
		private final String distributorCode;
		private final String distributorPassword;
		private final Address addressInformation;
		private final Referral referralInformation;
		private final Plan planInformation;
		private final List<Setting> accountSettings;

		public TrialAccount(final Account.Trial a, final UUID planId) {
			if (a != null) {
				this.accountName = a.company;
				this.initialUser = new APIUser(a.user);
				this.initialUser.enableConnectForUser = 'true';
				this.initialUser.userSettings = new List<Setting> {
					new Setting('allowSendOnBehalfOf', 'true'),
					new Setting('apiAccountWideAccess', 'true')
				};
				this.addressInformation = new Address(a.address);
			}
			// Invariant properties
			Organization__mdt ss = getSecureSettings();
			this.distributorCode = ss.DistributorCode__c;
			this.distributorPassword = ss.DistributorPassword__c;
			this.referralInformation = new Referral('DocuSignforSalesforce', 'AppExchange', 'DSFS_IPR');
			this.planInformation = new Plan(planId);
			this.accountSettings = new List<Setting> {
				new Setting('envelopeIntegrationAllowed', 'full'),
				new Setting('envelopeIntegrationEnabled', 'true')
			};
		}
	}

	private class TrialAccounts {
		public List<TrialAccount> newAccountRequests;

		public TrialAccounts(final Account.Trial a, final UUID planId) {
			this.newAccountRequests = new List<TrialAccount> {
				new TrialAccount(a, planId)
			};
		}
	}

	private class TrialAccountResult {
		public String accountId;
		public String accountIdGuid;
		public String accountName;
		public String userId;
		public String apiPassword;
		public String baseUrl;

		public Account.Membership toExternalForm() {
			final Url aUrl = String.isBlank(baseUrl) ? null : new Url(baseUrl);
			return new Account.Membership(
				Long.valueOf(accountId),
				UUID.fromString(accountIdGuid),
				accountName,
				UUID.fromString(userId),
				new Url('https://' + (new Url(baseUrl).getAuthority().toLowerCase()) + '/'),
				String.isBlank(apiPassword) ? '' : apiPassword);
		}
	}

	private class TrialAccountResults {
		public List<TrialAccountResult> newAccounts;

		public Account.Membership toExternalForm() {
			Account.Membership account = null;
			if (newAccounts != null && newAccounts.size() == 1) {
				return newAccounts[0].toExternalForm();
			}
			return account;
		}
	}

	public Account.Membership createTrialAccount(final Account.Trial account) {
		return this.createTrialAccount(account, RestAPI.defaultTimeout);
	}

	public Account.Membership createTrialAccount(final Account.Trial account, final Integer timeout) {
		final RestAPI.Response response = super.post(
			this.apiBaseUrl,
			new List<Object> { 'accounts' },
			QueryString.empty,
			this.getDefaultHeaders(),
			JSON.serialize(new TrialAccounts(account, this.environment.trialPlanId)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create account: ' + response.error);
			// TODO: Refactor this to rely on error codes instead of fragile messages.
			String errorMsg = response.error.description;
			if (String.isBlank(errorMsg)) {
				errorMsg = Label.AccountProvisioningFailed;
			} else if (errorMsg.indexOf('Member Email Not Allowed') > -1) {
				errorMsg = Label.UsernameNotAllowed;
			} else if (errorMsg.indexOf('Member Email And User Name Already Exists') > -1) {
				errorMsg = Label.AccountAlreadyExists;
			} else if (errorMsg.indexOf('Member Email And User Name Awaiting Activation') > -1) {
				errorMsg = Label.ActivationRequired;
			}
			throw new APIException(errorMsg);
		}

		return ((TrialAccountResults)JSON.deserialize(response.body, TrialAccountResults.class)).toExternalForm();
	}

	// Serialization objects for getAccount
	private class APIAccount {
		public String currentPlanId;
		public String planName;
		public String planStartDate;
		public String planEndDate;
		public String billingPeriodStartDate;
		public String billingPeriodEndDate;
		public String accountName;
		public String accountIdGuid;
		public String connectPermission;
		public String suspensionStatus;
		public String suspensionDate;

		public Account toExternalForm(final Environment env) {
			Date psd = StringUtils.parseDateTime(planStartDate).date();
			Date sd = String.isBlank(this.suspensionDate) ? null : StringUtils.parseDateTime(this.suspensionDate).date();
			return new Account(
				UUID.fromString(accountIdGuid),
				accountName,
				new Account.Plan(
					UUID.fromString(currentPlanId),
					planName,
					psd,
					StringUtils.parseDateTime(planEndDate).date()),
				new Account.Billing(
					sd == null ? StringUtils.parseDateTime(billingPeriodStartDate).date() : psd,
					sd == null ? StringUtils.parseDateTime(billingPeriodEndDate).date() : sd),
				stringToConnectPermission(connectPermission),
				env);
		}
	}

	public Account getAccount() {
		return this.getAccount(RestAPI.defaultTimeout);
	}

	public Account getAccount(final Integer timeout) {
		if (this.account == null) {
			final RestAPI.Response response = this.get(
				'',
				timeout);
			if (response.hasError) {
				this.log.error('Failed to read account: ' + response.error);
				throw new APIException(response.error);
			}

			this.account = ((AccountAPI.APIAccount)JSON.deserialize(response.body, AccountAPI.APIAccount.class))
				.toExternalForm(this.environment);
			if (this.account != null) {
				this.account = this.addPlanId(account, timeout);
			}
		}
		return this.account;
	}

	// Serialization object for account billing plan
	private class PlanId {
		public String planId;
	}

	private class BillingPlans {
		public PlanId billingPlan;
	}

	@TestVisible
	// HACK: Workaround for API-900. Need to call another API to get the correct planId :(
	private Account addPlanId(final Account account, final Integer timeout) {
		final RestAPI.Response response = this.get(
			'billing_plan',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read account billing plan: ' + response.error);
			throw new APIException(response.error);
		}

		final BillingPlans billing = (BillingPlans)JSON.deserialize(response.body, BillingPlans.class);
		if (billing == null || billing.billingPlan == null || String.isBlank(billing.billingPlan.planId)) {
			this.log.error('API returned no plan ID.');
			return account;
		}

		return account.withPlanId(UUID.fromString(billing.billingPlan.planId));
	}

	private class ViewResponse {
		public String url;
	}

	public Url getConsoleViewUrl() {
		return this.getConsoleViewUrl(RestAPI.defaultTimeout);
	}

	public Url getConsoleViewUrl(final Integer timeout) {
		final RestAPI.Response response = this.post(
			new List<Object> { 'views', 'console' },
			'{"suppressNavigation":"true"}',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get console view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	private class Setting {
		public String name;
		public String value;

		public Setting(final String name, final String value) {
			this.name = name;
			this.value = value;
		}
	}

	// getAccounts serialization objects
	private class LoginAccount {
		public String accountId;
		public String accountIdGuid;
		public String name;
		public String userId;
		public String baseUrl;
		public List<Setting> loginUserSettings;
		private Map<String, String> userSettings;

		public Account.Membership toExternalForm(final String apiPassword) {
			return new Account.Membership(
				Long.valueOf(accountId),
				UUID.fromString(accountIdGuid),
				name,
				UUID.fromString(userId),
				new Url('https://' + (new Url(baseUrl).getAuthority().toLowerCase()) + '/'),
				getUserSettings(),
				apiPassword);
		}

		public Map<String, String> getUserSettings() {
			if (userSettings == null) {
				userSettings = new Map<String, String>();
				if (loginUserSettings != null) {
					for (Setting s : loginUserSettings) {
						userSettings.put(s.name, s.value);
					}
				}
			}
			return userSettings;
		}
	}

	private class LoginInformation {
		public String apiPassword;
		public List<LoginAccount> loginAccounts;

		public List<Account.Membership> toExternalForm() {
			List<Account.Membership> result = new List<Account.Membership>();
			if (loginAccounts != null) {
				for (LoginAccount la : loginAccounts) {
					result.add(la.toExternalForm(apiPassword));
				}
			}
			return result;
		}
	}

	private class LegacyCredentials {
		private String Username;
		private String Password;
		private String IntegratorKey;

		public LegacyCredentials(final String username, final String password) {
			this.IntegratorKey = Application.INTEGRATOR_KEY;
			this.Username = username;
			this.Password = password;
		}
	}

	@TestVisible
	private static Account.ConnectPermission stringToConnectPermission(final String s) {
		if (s == 'full') {
			return Account.ConnectPermission.Full;
		} else if (s == 'sendOnly') {
			return Account.ConnectPermission.SendOnly;
		} else {
			return Account.ConnectPermission.None;
		}
	}

	private class UserSettings {
		public List<Setting> userSettings;

		public Map<String, String> toExternalForm() {
			final Map<String, String> settings = new Map<String, String>();
			if (userSettings != null) {
				for (Setting s : userSettings) {
					settings.put(s.name, s.value);
				}
			}
			return settings;
		}
	}

	@TestVisible
	private Map<String, String> getUserSettings(final Url baseUrl, final Long accountId, final UUID userId, final Integer timeout) {
		final RestAPI.Response response = super.get(
			baseUrl,
			new List<Object> { 'restapi', 'v2', 'accounts', accountId, 'users', userId, 'settings' },
			QueryString.empty,
			this.getDefaultHeaders(),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read user settings: ' + response.error.toString());
			throw new APIException(response.error);
		}

		final AccountAPI.UserSettings userSettings = (AccountAPI.UserSettings)JSON.deserialize(response.body, AccountAPI.UserSettings.class);
		return userSettings == null ? new Map<String, String>() : userSettings.toExternalForm();
	}

	@TestVisible
	private Boolean isValidAccount(final Account.Membership account) {
		Boolean isValid = false;
		if (account != null) {
			isValid = account.getFlag('canManageAccount')
				&& account.getFlag('canSendEnvelope')
				&& account.getFlag('apiAccountWideAccess')
				&& account.getFlag('allowSendOnBehalfOf');
		}
		return isValid;
	}

	@TestVisible
	private List<Account.Membership> getAccounts(final String authHeader, final Integer timeout) {
		RestAPI.Response response = get(
			this.apiBaseUrl,
			new List<Object> { 'login_information' },
			new QueryString(new Map<String, String> {
				'api_password' => 'true',
				'include_account_id_guid' => 'true',
				'login_settings' => 'all'
			}),
			new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'X-DocuSign-Authentication' => authHeader
			},
			timeout);
		if (response.hasError) {
			this.log.error('GET login_information failed: ' + response.error);
			throw new APIException(response.error);
		}
		return ((LoginInformation)JSON.deserialize(response.body, LoginInformation.class)).toExternalForm();
	}

	public Account.Credentials getAccountCredentials(final UUID accountId) {
		return this.getAccountCredentials(accountId, RestAPI.defaultTimeout);
	}

	public Account.Credentials getAccountCredentials(final UUID accountId, final Integer timeout) {
		Long accountNumber = null;
		String apiPassword = null;

		List<Account.Membership> memberships = this.getAccounts(this.legacyAuthHeader, timeout);
		if (Collection.isNotEmpty(memberships)) {
			apiPassword = memberships[0].apiPassword;
			for (Account.Membership m : memberships) {
				if (m.accountId == accountId) {
					accountNumber = m.accountNumber;
					break;
				}
			}
		}
		return new Account.Credentials(accountNumber, accountId, apiPassword);
	}

	public List<Account.Membership> getValidAccounts() {
		return getValidAccounts(RestAPI.defaultTimeout);
	}

	public List<Account.Membership> getValidAccounts(final Integer timeout) {
		if (this.baseUrl == null || this.username == null || String.isBlank(this.password))
			throw new DocuSignException(Label.AccountNotConfigured);

		List<Account.Membership> result = new List<Account.Membership>();
		List<Account.Membership> memberships = this.getAccounts(
			JSON.serialize(new LegacyCredentials(this.username, this.password)),
			timeout);
		if (Collection.isNotEmpty(memberships)) {
			if (memberships.size() == 1) {
				// Only one account returned. No need to call secondary API to get user settings.
				if (isValidAccount(memberships[0])) {
					result.add(memberships[0]);
				}
			} else {
				// DFS-3626: Work around API issue with user settings
				for (Account.Membership ua : memberships) {
					Account.Membership us = ua
						.withSettings(getUserSettings(ua.baseUrl, ua.accountNumber, ua.userId, timeout));
					if (isValidAccount(us)) {
						result.add(us);
					} else {
						log.info(String.format(
							'Invalid account ({0}) for DFS:\n\tManage account = {1}\n\tSend Envelopes = {2}'
								+ '\n\tSOBO = {3}\n\tAPI = {4}',
							new List<String> {
								String.valueOf(us.accountId),
								us.settings.get('canManageAccount'),
								us.settings.get('canSendEnvelope'),
								us.settings.get('allowSendOnBehalfOf'),
								us.settings.get('apiAccountWideAccess')
							}));
					}
				}
			}
		}
		return result;
	}

	// Serialization objects for getUser
	@TestVisible
	private static String stringToUserStatus(final String s) {
		if (s == 'Active') {
			return Account.USER_STATUS_ACTIVE;
		} else if (s == 'Closed') {
			return Account.USER_STATUS_CLOSED;
		} else if (s == 'ActivationSent' || s == 'ActivationRequired') {
			return Account.USER_STATUS_PENDING_ACTIVATION;
		} else if (s == 'Disabled') {
			return Account.USER_STATUS_DISABLED;
		} else {
			return Account.USER_STATUS_UNKNOWN;
		}
	}

	@TestVisible
	private static String userStatusToString(final String status) {
		if (status == Account.USER_STATUS_PENDING_ACTIVATION) {
			return 'activationSent';
		} else if (status == Account.USER_STATUS_ACTIVE) {
			return 'active';
		} else if (status == Account.USER_STATUS_CLOSED) {
			return 'closed';
		} else if (status == Account.USER_STATUS_DISABLED) {
			return 'disabled';
		}
		return null;
	}

	private class APIUser {
		public String userId;
		public String email;
		public String firstName;
		public String lastName;
		public String userName;
		public List<Setting> userSettings;
		public String userStatus;
		public String apiPassword;
		public ErrorDetails errorDetails;
		public String enableConnectForUser;

		public APIUser(final Account.User user) {
			this.userId = UUID.toString(user.id);
			this.email = user.email;
			this.firstName = user.firstName;
			this.lastName = user.lastName;
			this.userName = user.username;
			this.apiPassword = user.apiPassword;
			this.userSettings = new List<Setting> {
				new Setting('canManageAccount', String.valueOf(user.canManageAccount)),
				new Setting('canSendEnvelope', String.valueOf(user.canSendEnvelope))
			};
			this.userStatus = userStatusToString(user.status);
		}

		public APIUser(final Account.TrialUser user) {
			this.email = user.email;
			this.firstName = user.firstName;
			this.lastName = user.lastName;
			this.userName = user.email;
			this.userSettings = new List<Setting> {
				new Setting('canManageAccount', 'true'),
				new Setting('canSendEnvelope', 'true')
			};
		}

		private APIError errorExternalForm() {
			APIError e;
			if (errorDetails == null || String.isBlank(errorDetails.errorCode) || errorDetails.errorCode == SUCCESS) {
				e = APIError.none;
			} else if (errorDetails.errorCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, errorDetails.message);
			} else if (errorDetails.errorCode == USER_DOES_NOT_EXIST || errorDetails.errorCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, errorDetails.message);
			} else {
				e = new APIError(APIErrorCode.BAD_REQUEST, String.format('[{0}] {1}',
					new List<String> { errorDetails.errorCode, errorDetails.message }));
			}
			return e;
		}

		public Account.User toExternalForm(final Id sourceId, final Boolean canManageAccount) {

			Boolean isAdmin = canManageAccount;
			Boolean isSender = true;
			if (this.userSettings != null) {
				for (Setting s : this.userSettings) {
					if (s.name == 'canManageAccount') {
						isAdmin = StringUtils.parseBoolean(s.value);
					} else if (s.name == 'canSendEnvelope') {
						isSender = StringUtils.parseBoolean(s.value);
					}
				}
			}
			return new Account.User(
				UUID.tryParse(this.userId),
				this.userName,
				this.email,
				this.firstName,
				this.lastName,
				this.apiPassword,
				stringToUserStatus(this.userStatus),
				isAdmin,
				isSender,
				sourceId,
				errorExternalForm());
		}
	}

	private class NewUsers {
		public List<AccountAPI.APIUser> newUsers;

		public NewUsers(final List<Account.User> users) {
			this.newUsers = new List<APIUser>();
			if (users != null) {
				for (Account.User u : users) {
					this.newUsers.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final List<Account.User> users) {
			Map<String, Account.User> emailToUsers = new Map<String, Account.User>();
			for (Account.User u : users) {
				emailToUsers.put(u.email, u);
			}
			List<Account.User> result = new List<Account.User>();
			if (this.newUsers != null) {
				for (AccountAPI.APIUser u : this.newUsers) {
					Account.User original = emailToUsers.get(u.email);
					result.add(u.toExternalForm(original == null ? null : original == null ? null : original.sourceId,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	public List<Account.User> addUsers(final List<Account.User> users) {
		return this.addUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> addUsers(final List<Account.User> users, final Integer timeout) {
		if (users == null || users.isEmpty()) throw new DocuSignException('No users to add.');

		final RestAPI.Response response = this.post(
			'users',
			JSON.serialize(new NewUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((NewUsers)JSON.deserialize(response.body, NewUsers.class)).toExternalForm(users);
	}

	// Serialization objects for removeUsers
	private class RemoveUsers {
		public List<AccountAPI.APIUser> users;

		public RemoveUsers(final List<Account.User> dsUsers) {
			this.users = new List<AccountAPI.APIUser>();
			if (dsUsers != null) {
				for (Account.User u : dsUsers) {
					this.users.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final List<Account.User> users) {
			Map<String, Account.User> emailToUsers = new Map<String, Account.User>();
			for (Account.User u : users) {
				emailToUsers.put(u.email, u);
			}
			List<Account.User> result = new List<Account.User>();
			if (this.users != null) {
				for (AccountAPI.APIUser u : this.users) {
					Account.User original = emailToUsers.get(u.email);
					result.add(u.toExternalForm(original == null ? null : original == null ? null : original.sourceId,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	public List<Account.User> removeUsers(final List<Account.User> users) {
		return this.removeUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> removeUsers(final List<Account.User> users, final Integer timeout) {
		if (users == null || users.isEmpty()) throw new DocuSignException('No users to remove.');

		final RestAPI.Response response = this.del(
			'users',
			JSON.serialize(new RemoveUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to remove users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((RemoveUsers)JSON.deserialize(response.body, RemoveUsers.class)).toExternalForm(users);
	}

	// Serialization objects for custom fields
	private class ListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public CustomField toExternalForm() {
			return CustomField.newListField(name, value, listItems, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	private class TextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public CustomField toExternalForm() {
			return CustomField.newTextField(name, value, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	private class CustomFields {
		public List<TextCustomField> textCustomFields;
		public List<ListCustomField> listCustomFields;

		public List<CustomField> toExternalForm() {
			final List<CustomField> cfs = new List<CustomField>();

			if (this.textCustomFields != null) {
				for (TextCustomField cf : this.textCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			if (this.listCustomFields != null) {
				for (ListCustomField cf : listCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			return cfs;
		}
	}

	public List<CustomField> getCustomFields() {
		return this.getCustomFields(RestAPI.defaultTimeout);
	}

	public List<CustomField> getCustomFields(final Integer timeout) {
		if (accountCustomFields == null) {
			final RestAPI.Response response = this.get(
				'custom_fields',
				timeout);
			if (response.hasError) {
				this.log.error('Failed to get get custom fields: ' + response.error.toString());
				throw new APIException(response.error);
			}

			accountCustomFields = ((CustomFields)JSON.deserialize(response.body, CustomFields.class)).toExternalForm();
		}
		return accountCustomFields;
	}

	private class MergeField {
		public String configurationType;
		public String path;
		public String writeBack;
		public String allowSenderToEdit;

		public MergeField(final DocumentCustomField.MergeField dsMF) {
			if (dsMF != null) {
				this.configurationType = 'salesforce';
				this.path = dsMF.path;
				this.writeBack = String.valueOf(dsMF.writeBack);
				this.allowSenderToEdit = String.valueOf(dsMF.editable);
			}
		}

		public DocumentCustomField.MergeField toExternalForm() {
			return new DocumentCustomField.MergeField(
				path,
				StringUtils.parseBoolean(writeBack),
				StringUtils.parseBoolean(allowSenderToEdit));
		}
	}

	private class CustomTab {
		public String customTabId;
		public String tabLabel;
		public String type;
		public String anchor;
		public String shared;
		public List<String> items;
		public String lastModified;
		public String initialValue;
		public String required;
		public String locked;
		public String editable;
		public String includedInEmail;
		public String font;
		public String fontColor;
		public String fontSize;
		public String concealValueOnDocument;
		public String disableAutoSize;
		public String name;
		public String bold;
		public String italic;
		public String underline;
		public String maximumLength;
		public String validationPattern;
		public String validationMessage;
		public MergeField mergeField;

		public CustomTab(final DocumentCustomField dsCT) {
			if (dsCT != null) {
				this.customTabId = String.valueOf(dsCT.id);
				this.tabLabel = StringUtils.fromString(dsCT.label);
				this.type = dsCT.type;
				this.anchor = StringUtils.fromString(dsCT.autoPlaceText);
				this.items = dsCT.items != null ? dsCT.items : new List<String>();
				this.initialValue = StringUtils.fromString(dsCT.initialValue);
				if (dsCT.options != null) {
					DocumentCustomField.Options dsOptions = dsCT.options;
					this.shared = String.valueOf(dsOptions.shared);
					this.required = String.valueOf(dsOptions.required);
					this.locked = String.valueOf(dsOptions.readOnly);
					this.editable = String.valueOf(dsOptions.editable);
					this.includedInEmail = String.valueOf(dsOptions.includeInEmail);
				}
				if (dsCT.formatting != null) {
					final DocumentCustomField.Formatting dsFormat = dsCT.formatting;
					if (dsFormat.font != null) {
						final DocumentCustomField.Font dsFont = dsFormat.font;
						this.font = dsFont.family;
						this.fontColor = dsFont.color;
						this.fontSize = dsFont.size;
						this.bold = String.valueOf(dsFont.bold);
						this.italic = String.valueOf(dsFont.italic);
						this.underline = String.valueOf(dsFont.underline);
					}
					this.concealValueOnDocument = String.valueOf(dsFormat.masked);
					this.disableAutoSize = String.valueOf(dsFormat.fixedSize);
				}
				this.name = dsCT.tooltip;
				if (dsCT.validation != null) {
					final DocumentCustomField.Validation dsV = dsCT.validation;
					this.maximumLength = String.valueOf(dsV.maximumCharacters);
					this.validationPattern = StringUtils.fromString(dsV.regularExpression);
					this.validationMessage = StringUtils.fromString(dsV.errorMessage);
				}
				if (dsCT.mergeField != null) {
					this.mergeField = new MergeField(dsCT.mergeField);
				}
			}
		}

		public DocumentCustomField toExternalForm() {
			return new DocumentCustomField(
				UUID.tryParse(customTabId),
				tabLabel,
				type,
				mergeField == null ? null : mergeField.toExternalForm(),
				items,
				initialValue,
				new DocumentCustomField.Options(
					StringUtils.parseBoolean(required),
					StringUtils.parseBoolean(locked),
					StringUtils.parseBoolean(shared),
					StringUtils.parseBoolean(editable),
					StringUtils.parseBoolean(includedInEmail)),
				new DocumentCustomField.Formatting(
					new DocumentCustomField.Font(
						font,
						fontColor,
						fontSize,
						StringUtils.parseBoolean(bold),
						StringUtils.parseBoolean(italic),
						StringUtils.parseBoolean(underline)
					),
					StringUtils.parseBoolean(concealValueOnDocument),
					StringUtils.parseBoolean(disableAutoSize)),
				new DocumentCustomField.Validation(
					StringUtils.parseInteger(maximumLength),
					validationPattern,
					validationMessage),
				name,
				anchor,
				StringUtils.parseDateTime(lastModified));
		}
	}

	private class CustomTabs {
		public List<CustomTab> tabs;

		public List<DocumentCustomField> toExternalForm() {
			final List<DocumentCustomField> cts = new List<DocumentCustomField>();
			if (tabs != null) {
				for (CustomTab ct : tabs) {
					cts.add(ct.toExternalForm());
				}
			}
			return cts;
		}
	}

	public List<DocumentCustomField> getDocumentCustomFields() {
		return this.getDocumentCustomFields(RestAPI.defaultTimeout);
	}

	public List<DocumentCustomField> getDocumentCustomFields(final Integer timeout) {
		final RestAPI.Response response = this.get(
			'tab_definitions',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get custom fields: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((CustomTabs)JSON.deserialize(response.body, CustomTabs.class)).toExternalForm();
	}

	public UUID saveDocumentCustomField(final DocumentCustomField customTab) {
		return this.saveDocumentCustomField(customTab, RestAPI.defaultTimeout);
	}

	public UUID saveDocumentCustomField(final DocumentCustomField customTab, final Integer timeout) {
		if (customTab == null) throw new DocuSignException(Label.UndefinedArgument);

		final CustomTab apiCF = new CustomTab(customTab);

		RestAPI.Response response;
		if (!UUID.isDefined(customTab.id)) {
			// Create new custom field
			response = this.post(
				'tab_definitions',
				JSON.serialize(apiCF),
				timeout);
		} else {
			// Update existing custom field
			response = this.put(
				new List<Object> { 'tab_definitions', customTab.id },
				JSON.serialize(apiCF),
				timeout);
		}

		if (response.hasError) {
			this.log.error('Failed to save custom tab: ' + response.error.toString());
			throw new APIException(response.error);
		}

		final CustomTab result = (CustomTab)JSON.deserialize(response.body, CustomTab.class);
		return UUID.fromString(result.customTabId);
	}

	public Boolean deleteDocumentCustomField(final UUID customTabId) {
		return deleteDocumentCustomField(customTabId, RestAPI.defaultTimeout);
	}

	public Boolean deleteDocumentCustomField(final UUID customTabId, final Integer timeout) {
		if (customTabId == null) throw new DocuSignException(Label.UndefinedArgument);

		final RestAPI.Response response = this.del(
			new List<Object> { 'tab_definitions', customTabId },
			timeout);
		if (response.hasError) {
			this.log.error('Failed to delete custom tab: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return true;
	}
}
