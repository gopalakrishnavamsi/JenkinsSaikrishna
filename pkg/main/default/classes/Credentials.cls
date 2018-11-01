public with sharing class Credentials {

	@TestVisible
	private static Credentials self;
	private static final Credentials.Database DB = new Credentials.Database();
	private static AccountCredentials accountCredentials = null;
	private static final Map<Id, UserCredentials> userCredentials = new Map<Id, UserCredentials>();

	public Environment environment { get; private set; }
	public UUID accountId { get; private set; }
	public Long accountNumber { get; private set; }
	public String email { get; private set; }
	public String username { get; private set; }
	public String password { get; private set; }
	public Boolean useSendOnBehalfOf { get; private set; }
	public String sendOnBehalfOf { get; private set; }
	private final Boolean isDefault;
	public Boolean isValid {
		get {
			return this.isAccountValid && this.isUserValid;
		}
	}
	public Boolean isAccountValid {
		get {
			return this.environment != null
				&& this.environment.isValid
				&& (this.accountId != null || !this.isDefault)
				&& String.isNotBlank(this.username)
				&& String.isNotBlank(this.password);
		}
	}
	public Boolean isUserValid {
		get {
			return (!this.useSendOnBehalfOf || String.isNotBlank(this.sendOnBehalfOf));
		}
	}

	@TestVisible
	private Credentials(
		final Environment environment,
		final UUID accountId,
		final Long accountNumber,
		final String email,
		final String username,
		final String password,
		final Boolean useSendOnBehalfOf,
		final String sendOnBehalfOf,
		final Boolean isDefault) {

		this.environment = environment;
		this.accountId = accountId;
		this.accountNumber = accountNumber;
		this.email = email;
		this.username = username;
		this.password = password;
		this.useSendOnBehalfOf = useSendOnBehalfOf;
		this.sendOnBehalfOf = sendOnBehalfOf;
		this.isDefault = isDefault;
	}

	public static Boolean isAccountValid() {
		return getInstance(UserInfo.getUserId(), false).isAccountValid;
	}

	public static Credentials getInstance() {
		return getInstance(UserInfo.getUserId(), true);
	}

	public static Credentials getInstance(final Environment environment, final String username, final String password) {
		return new Credentials(environment, null, null, null, username, password, false, null, false);
	}

	private static void validate(final Credentials c) {
		if (c == null) throw new DocuSignException(Label.UndefinedArgument);

		if (!c.isAccountValid) {
			throw UnauthorizedException.accountNotConfigured();
		} else if (!c.isUserValid) {
			throw UnauthorizedException.mayRequireActivation();
		}
	}

	@TestVisible
	private static Credentials getInstance(final Id userId, final Boolean validate) {
		Credentials result = null;
		if (userId == UserInfo.getUserId()) { // 99% case user needs stored DS creds for API calls
			if (self == null) {
				result = buildAPICredentials(getAccountCredentials(), getUserCredentials(userId));
				if (validate) validate(result);
				self = result;
			}
			result = self;
		} else {
			result = buildAPICredentials(getAccountCredentials(), getUserCredentials(userId));
			if (validate) validate(result);
		}
		return result;
	}

	@TestVisible
	private static Credentials buildAPICredentials(
		final AccountCredentials accountCredentials,
		final UserCredentials userCredentials) {

		Credentials result = null;
		if (accountCredentials != null && userCredentials != null) {
			if (String.isNotBlank(userCredentials.username)) { // Valid user either with or without SOBO
				if (accountCredentials.useSendOnBehalfOf) {
					result = new Credentials(
						accountCredentials.environment,
						accountCredentials.accountId,
						accountCredentials.accountNumber,
						accountCredentials.email,
						accountCredentials.username,
						accountCredentials.password,
						true,
						userCredentials.username,
						true);
				} else {
					result = new Credentials(
						accountCredentials.environment,
						accountCredentials.accountId,
						accountCredentials.accountNumber,
						accountCredentials.email,
						userCredentials.username,
						userCredentials.password,
						false,
						null,
						true);
				}
			} else if (accountCredentials.useSystemSender) { // Use account credentials and no SOBO
				result = new Credentials(
					accountCredentials.environment,
					accountCredentials.accountId,
					accountCredentials.accountNumber,
					accountCredentials.email,
					accountCredentials.username,
					accountCredentials.password,
					false,
					null,
					true);
			} else { // Invalid user
				result = new Credentials(
					accountCredentials.environment,
					accountCredentials.accountId,
					accountCredentials.accountNumber,
					accountCredentials.email,
					accountCredentials.username,
					accountCredentials.password,
					true,
					null,
					true);
			}
		} else {
			LoggerService.getInstance().error('Account and/or user configuration is null.');
			throw new DocuSignException(Label.ConfigurationError);
		}
		return result;
	}

	public static Credentials save(
		final Environment environment,
		final UUID accountId,
		final Long accountNumber,
		final String email,
		final String username,
		final String password,
		final Boolean canManageAccount) {

		return save(UserInfo.getUserId(), environment, accountId, accountNumber, email, username, password,
			canManageAccount);
	}

	@TestVisible
	private static Credentials save(
		final Id userId,
		final Environment environment,
		final UUID accountId,
		final Long accountNumber,
		final String email,
		final String username,
		final String password,
		final Boolean canManageAccount) {

		Boolean useSOBO = getUseSendOnBehalfOf(AccountSettings__c.getOrgDefaults());
		Credentials.accountCredentials = DB.updateAccountCredentials(
			environment,
			accountId,
			accountNumber,
			email,
			useSOBO ? username : null,
			useSOBO ? password : null);
		Credentials.UserCredentials uc = DB.updateUserCredentials(
			userId,
			username,
			useSOBO ? null : password,
			canManageAccount);
		Credentials.userCredentials.put(userId, uc);
		self = buildAPICredentials(Credentials.accountCredentials, uc);
		return self;
	}

	public static void addUsers(final Map<Id, UserCredentials> userCredentials) {
		Set<Id> adminIds = new Set<Id>();
		Set<Id> userIds = new Set<Id>();
		for (Id userId : userCredentials.keySet()) {
			UserCredentials uc = userCredentials.get(userId);
			if (uc != null) {
				if (uc.canManageAccount) {
					adminIds.add(userId);
				} else {
					userIds.add(userId);
				}
			}
		}
		DB.updateUserCredentials(userCredentials);

		if (!userIds.isEmpty()) {
			assignUserPermissionSet(userIds);
		}

		if (!adminIds.isEmpty()) {
			assignAdminPermissionSet(adminIds);
		}
	}

	public static void clear(final Boolean resetUsers) {
		DB.deleteAccountCredentials();
		if (resetUsers) {
			Set<Id> userIds = new Set<Id>();
			Boolean isWorking = true;
			while (isWorking) {
				List<User> users = [
					SELECT Id, Username__c, CanManageAccount__c
					FROM User
					WHERE Username__c != NULL
					LIMIT 200
				];
				if (Collection.isNotEmpty(users)) {
					DB.deleteUserCredentials(users);
					for (User u : users) {
						if (u.Id != UserInfo.getUserId()) userIds.add(u.Id);
					}
				} else {
					isWorking = false;
				}
			}
			removePermissionSets(userIds);
		}
		self = null;
	}

	public static void clear(final Set<Id> userIds) {
		DB.deleteUserCredentials([SELECT Id, Username__c FROM User WHERE Id IN :userIds]);
		removePermissionSets(userIds);
		self = null;
	}

	@Future
	private static void assignAdminPermissionSet(final Set<Id> userIds) {
		Permissions.assignDocuSignAdministratorPermissionSet(userIds);
	}

	@Future
	private static void assignUserPermissionSet(final Set<Id> userIds) {
		Permissions.assignDocuSignUserPermissionSet(userIds);
	}

	@Future
	private static void removePermissionSets(final Set<Id> userIds) {
		Permissions.removeDocuSignPermissionSets(userIds);
	}

	@TestVisible
	private static AccountCredentials getAccountCredentials() {
		if (Credentials.accountCredentials == null) {
			Credentials.accountCredentials = DB.queryAccountCredentials();
		}
		return Credentials.accountCredentials;
	}

	@TestVisible
	private static UserCredentials getUserCredentials(final Id userId) {
		if (!userCredentials.containsKey(userId)) {
			Credentials.userCredentials.put(userId, DB.queryUserCredentials(userId));
		}
		return Credentials.userCredentials.get(userId);
	}

	@TestVisible
	private class AccountCredentials {
		public final Environment environment;
		public final UUID accountId;
		public final Long accountNumber;
		public final String email;
		public final String username;
		public final String password;
		public final Boolean useSendOnBehalfOf;
		public final Boolean useSystemSender;

		public AccountCredentials(
			final Environment environment,
			final UUID accountId,
			final Long accountNumber,
			final String email,
			final String username,
			final String password,
			final Boolean useSendOnBehalfOf,
			final Boolean useSystemSender) {

			this.environment = environment;
			this.accountId = accountId;
			this.accountNumber = accountNumber;
			this.email = email;
			this.username = username;
			this.password = password;
			this.useSendOnBehalfOf = useSendOnBehalfOf;
			this.useSystemSender = useSystemSender;
		}
	}

	public class UserCredentials {
		public String username { get; private set; }
		public String password { get; private set; }
		public Boolean canManageAccount { get; private set; }

		public UserCredentials(final String username, final String password) {
			this(username, password, false);
		}

		public UserCredentials(final String username, final String password, final Boolean canManageAccount) {
			this.username = username;
			this.password = password;
			this.canManageAccount = canManageAccount;
		}
	}

	private static Boolean getUseSendOnBehalfOf(final AccountSettings__c settings) {
		return settings == null || settings.Id == null || settings.UseSendOnBehalfOf__c == null || settings.UseSendOnBehalfOf__c;
	}

	private static Boolean getUseSystemSender(final AccountSettings__c settings) {
		return settings != null && settings.Id != null && settings.UseSystemSender__c != null && settings.UseSystemSender__c;
	}

	@TestVisible
	private with sharing class Database {

		public AccountCredentials queryAccountCredentials() {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			if (String.isBlank(settings.Environment__c)) {
				return new AccountCredentials(Environment.invalid, null, null, null, null, null, false, false);
			}

			return new AccountCredentials(
				Environment.fromUrl(settings.BaseUrl__c == null ? null : new Url(settings.BaseUrl__c)),
				UUID.tryParse(settings.AccountId__c),
				(Long)settings.AccountNumber__c,
				settings.Email__c,
				settings.Username__c,
				settings.Password__c,
				getUseSendOnBehalfOf(settings),
				getUseSystemSender(settings));
		}

		public UserCredentials queryUserCredentials(final Id userId) {
			UserSettings__c settings = UserSettings__c.getInstance(userId);
			return new UserCredentials(settings.Username__c, settings.Password__c);
		}

		public AccountCredentials updateAccountCredentials(
			final Environment environment,
			final UUID accountId,
			final Long accountNumber,
			final String email,
			final String username,
			final String password) {

			AccountSettings__c orgSettings = AccountSettings__c.getOrgDefaults();
			orgSettings.Environment__c = environment == null || environment.environment == null
				? null : environment.environment.name().toLowerCase();
			orgSettings.BaseUrl__c = environment == null || environment.baseUrl == null
				? null : environment.baseUrl.toExternalForm();
			orgSettings.AccountId__c = String.valueOf(accountId);
			orgSettings.AccountNumber__c = accountNumber;
			orgSettings.Email__c = email;
			orgSettings.Username__c = username;
			orgSettings.Password__c = password;
			upsert orgSettings;
			orgSettings = AccountSettings__c.getOrgDefaults();

			return new AccountCredentials(
				environment,
				accountId,
				accountNumber,
				email,
				username,
				password,
				getUseSendOnBehalfOf(orgSettings),
				getUseSystemSender(orgSettings));
		}

		public UserCredentials updateUserCredentials(
			final Id userId,
			final String username,
			final String password,
			final Boolean canManageAccount) {

			Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
				'Username__c', 'CanManageAccount__c'
			});

			List<User> users = [SELECT Id, Username__c FROM User WHERE Id = :userId LIMIT 1];
			if (Collection.isNotEmpty(users)) {
				users[0].Username__c = username;
				users[0].CanManageAccount__c = canManageAccount;
				update users[0];
			}

			UserSettings__c userSettings = UserSettings__c.getInstance(userId);
			userSettings.Username__c = username;
			userSettings.Password__c = password;
			upsert userSettings;

			return new UserCredentials(username, password, canManageAccount);
		}

		public void updateUserCredentials(final Map<Id, UserCredentials> credentials) {
			if (credentials != null && !credentials.isEmpty()) {
				Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
					'Username__c', 'CanManageAccount__c'
				});

				List<User> users = [SELECT Id, Username__c FROM User WHERE Id IN :credentials.keySet()];
				List<UserSettings__c> settings = new List<UserSettings__c>();
				for (User u : users) {
					UserCredentials uc = credentials.get(u.Id);
					UserSettings__c us = UserSettings__c.getInstance(u.Id);
					if (uc == null) {
						u.Username__c = null;
						u.CanManageAccount__c = false;
						us.Username__c = null;
						us.Password__c = null;
					} else {
						u.Username__c = uc.username;
						u.CanManageAccount__c = uc.canManageAccount;
						us.Username__c = uc.username;
						us.Password__c = uc.password;
					}
					settings.add(us);
				}
				update users;
				upsert settings;
			}
		}

		public void deleteAccountCredentials() {
			AccountSettings__c orgDefaults = AccountSettings__c.getOrgDefaults();
			orgDefaults.Environment__c = null;
			orgDefaults.BaseUrl__c = null;
			orgDefaults.AccountId__c = null;
			orgDefaults.AccountNumber__c = null;
			orgDefaults.Email__c = null;
			orgDefaults.Username__c = null;
			orgDefaults.Password__c = null;
			orgDefaults.Features__c = null;
			orgDefaults.FeaturesLastChecked__c = null;
			upsert orgDefaults;
		}

		public void deleteUserCredentials(final List<User> users) {
			if (Collection.isNotEmpty(users)) {
				Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> { 'Username__c' });

				List<User> toRemove = new List<User>();
				List<UserSettings__c> settings = new List<UserSettings__c>();

				for (User u : users) {
					if (String.isNotBlank(u.Username__c)) {
						u.Username__c = null;
						u.CanManageAccount__c = false;
						toRemove.add(u);
					}

					UserSettings__c s = UserSettings__c.getInstance(u.Id);
					s.Username__c = null;
					s.Password__c = null;
					settings.add(s);
				}

				update toRemove;
				upsert settings;
			}
		}
	}
}