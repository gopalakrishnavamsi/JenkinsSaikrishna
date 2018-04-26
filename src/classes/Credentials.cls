public with sharing class Credentials {

	@TestVisible
	private static Credentials self;
	private static final Credentials.Database DB = new Credentials.Database();
	private static AccountCredentials accountCredentials = null;
	private static final Map<Id, UserCredentials> userCredentials = new Map<Id, UserCredentials>();

	public Environment environment { get; private set; }
	public UUID accountId { get; private set; }
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
		final String username,
		final String password,
		final Boolean useSendOnBehalfOf,
		final String sendOnBehalfOf,
		final Boolean isDefault) {

		this.environment = environment;
		this.accountId = accountId;
		this.username = username;
		this.password = password;
		this.useSendOnBehalfOf = useSendOnBehalfOf;
		this.sendOnBehalfOf = sendOnBehalfOf;
		this.isDefault = isDefault;
	}

	public static Credentials getInstance() {
		return getInstance(UserInfo.getUserId(), true);
	}

	public static Credentials getInstance(final Environment environment, final String username, final String password) {
		return new Credentials(environment, null, username, password, false, null, false);
	}

	@TestVisible
	private static Credentials getInstance(final Id userId, final Boolean validate) {
		if (userId == UserInfo.getUserId()) { // 99% case user needs stored DS creds for API calls
			if (self == null) {
				Credentials that = buildAPICredentials(getAccountCredentials(), getUserCredentials(userId));
				if (validate && !that.isAccountValid) {
					throw new UnauthorizedException(Label.AccountNotConfigured);
				} else if (validate && !that.isUserValid) {
					throw new UnauthorizedException(Label.MustBeActivated);
				}
				self = that;
			}
			return self;
		}
		return buildAPICredentials(getAccountCredentials(), getUserCredentials(userId));
	}

	@TestVisible
	private static Credentials buildAPICredentials(
		final AccountCredentials accountCredentials,
		final UserCredentials userCredentials) {

		Credentials result = null;
		if (accountCredentials != null && userCredentials != null) {
			if (accountCredentials.useSendOnBehalfOf) {
				result = new Credentials(
					accountCredentials.environment,
					accountCredentials.accountId,
					accountCredentials.username,
					accountCredentials.password,
					true,
					userCredentials.username,
					true);
			} else {
				result = new Credentials(
					accountCredentials.environment,
					accountCredentials.accountId,
					userCredentials.username,
					userCredentials.password,
					false,
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
		final String username,
		final String password,
		final Boolean useSendOnBehalfOf,
		final Boolean setupComplete) {

		return save(UserInfo.getUserId(), environment, accountId, username, password,
			useSendOnBehalfOf, setupComplete);
	}

	@TestVisible
	private static Credentials save(
		final Id userId,
		final Environment environment,
		final UUID accountId,
		final String username,
		final String password,
		final Boolean useSendOnBehalfOf,
		final Boolean setupComplete) {

		Credentials.accountCredentials = DB.updateAccountCredentials(
			environment,
			accountId,
			useSendOnBehalfOf ? username : null,
			useSendOnBehalfOf ? password : null,
			useSendOnBehalfOf,
			setupComplete);
		Credentials.UserCredentials uc = DB.updateUserCredentials(
			userId,
			username,
			useSendOnBehalfOf ? null : password);
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
				if (uc.isAdmin) {
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
				List<User> users = [SELECT Id, Username__c FROM User WHERE Username__c != null LIMIT 200];
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
		try {
			Permissions.assignDocuSignAdministratorPermissionSet(userIds);
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Failed to assign the DocuSign Administrator permission set');
		}
	}

	@Future
	private static void assignUserPermissionSet(final Set<Id> userIds) {
		try {
			Permissions.assignDocuSignUserPermissionSet(userIds);
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Failed to assign the DocuSign User permission set');
		}
	}

	@Future
	private static void removePermissionSets(final Set<Id> userIds) {
		try {
			Permissions.removeDocuSignPermissionSets(userIds);
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Failed to remove the DocuSign permission sets');
		}
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
		public final String username;
		public final String password;
		public final Boolean useSendOnBehalfOf;

		public AccountCredentials(
			final Environment environment,
			final UUID accountId,
			final String username,
			final String password,
			final Boolean useSendOnBehalfOf) {

			this.accountId = accountId;
			this.environment = environment;
			this.username = username;
			this.password = password;
			this.useSendOnBehalfOf = useSendOnBehalfOf;
		}
	}

	public class UserCredentials {
		public String username { get; private set; }
		public String password { get; private set; }
		public Boolean isAdmin { get; private set; }

		public UserCredentials(final String username, final String password) {
			this(username, password, false);
		}

		public UserCredentials(final String username, final String password, final Boolean isAdmin) {
			this.username = username;
			this.password = password;
			this.isAdmin = isAdmin;
		}
	}

	@TestVisible
	private with sharing class Database {

		public AccountCredentials queryAccountCredentials() {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();

			if (String.isBlank(settings.Environment__c))
				return new AccountCredentials(Environment.invalid, null, null, null, false);

			return new AccountCredentials(
				Environment.fromUrl(settings.BaseUrl__c == null ? null : new Url(settings.BaseUrl__c)),
				UUID.tryParse(settings.AccountId__c),
				settings.Username__c,
				settings.Password__c,
				settings.UseSendOnBehalfOf__c != null && settings.UseSendOnBehalfOf__c);
		}

		public UserCredentials queryUserCredentials(final Id userId) {
			UserSettings__c settings = UserSettings__c.getInstance(userId);
			return new UserCredentials(settings.Username__c, settings.Password__c);
		}

		public AccountCredentials updateAccountCredentials(
			final Environment environment,
			final UUID accountId,
			final String username,
			final String password,
			final Boolean useSendOnBehalfOf,
			final Boolean setupComplete) {

			AccountSettings__c orgSettings = AccountSettings__c.getOrgDefaults();
			orgSettings.Environment__c = environment == null || environment.environment == null
				? null : environment.environment.name().toLowerCase();
			orgSettings.BaseUrl__c = environment == null || environment.baseUrl == null
				? null : environment.baseUrl.toExternalForm();
			orgSettings.AccountId__c = String.valueOf(accountId);
			orgSettings.UseSendOnBehalfOf__c = useSendOnBehalfOf != null && useSendOnBehalfOf;
			orgSettings.Username__c = username;
			orgSettings.Password__c = password;
			orgSettings.SetupComplete__c = setupComplete;
			upsert orgSettings;

			return new AccountCredentials(environment, accountId, username, password, useSendOnBehalfOf);
		}

		public UserCredentials updateUserCredentials(
			final Id userId,
			final String username,
			final String password) {

			// Cannot enforce FLS on first run as no one has edit permissions to the custom field.
			//Permissions.verifyIsUpdateable('User', new List<String> { 'Username__c' });

			List<User> users = [SELECT Id, Username__c FROM User WHERE Id = :userId LIMIT 1];
			if (Collection.isNotEmpty(users)) {
				users[0].Username__c = username;
				update users[0];
			}

			UserSettings__c userSettings = UserSettings__c.getInstance(userId);
			userSettings.Username__c = username;
			userSettings.Password__c = password;
			upsert userSettings;

			return new UserCredentials(username, password);
		}

		public void updateUserCredentials(final Map<Id, UserCredentials> credentials) {
			if (credentials != null && !credentials.isEmpty()) {
				Permissions.verifyIsUpdateable('User', new List<String> { 'Username__c' });

				List<User> users = [SELECT Id, Username__c FROM User WHERE Id IN :credentials.keySet()];
				List<UserSettings__c> settings = new List<UserSettings__c>();
				for (User u : users) {
					UserCredentials uc = credentials.get(u.Id);
					UserSettings__c us = UserSettings__c.getInstance(u.Id);
					if (uc == null) {
						u.Username__c = null;
						us.Username__c = null;
						us.Password__c = null;
					} else {
						u.Username__c = uc.username;
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
			orgDefaults.SetupComplete__c = false;
			orgDefaults.Environment__c = null;
			orgDefaults.BaseUrl__c = null;
			orgDefaults.AccountId__c = null;
			orgDefaults.Username__c = null;
			orgDefaults.Password__c = null;
			upsert orgDefaults;
		}

		public void deleteUserCredentials(final List<User> users) {
			if (Collection.isNotEmpty(users)) {
				Permissions.verifyIsUpdateable('User', new List<String> { 'Username__c' });

				List<User> toRemove = new List<User>();
				List<UserSettings__c> settings = new List<UserSettings__c>();

				for (User u : users) {
					if (String.isNotBlank(u.Username__c)) {
						u.Username__c = null;
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
