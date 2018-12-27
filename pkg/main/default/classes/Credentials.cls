public with sharing class Credentials {

	@TestVisible
	private static Credentials self;
	@TestVisible
	private static final Credentials.Database DB = new Credentials.Database();
	private static AccountCredentials accountCredentials = null;
	private static final Map<Id, UserCredentials> userCredentials = new Map<Id, UserCredentials>();
	@TestVisible
	private static final Integer MAX_TOKEN_LENGTH = 1530;

	private Boolean isDirty = false;
	public DocuSign.Environment environment { get; private set; }
	public Url accountBaseUrl { get; private set; }
	public Url eSignatureBaseUrl { get; private set; }
	public UUID accountId { get; private set; }
	public Long accountNumber { get; private set; }
	public String accountName { get; private set; }
	public String email { get; private set; }
	public UUID userId { get; private set; }
	public AccessToken token { get; private set; }
	public Boolean isValid {
		get {
			return this.isAccountValid && this.isUserValid;
		}
	}
	public Boolean isAccountValid {
		get {
			return DocuSign.isValidUrl(this.accountBaseUrl)
				&& DocuSign.isValidUrl(this.eSignatureBaseUrl)
				&& UUID.isNotEmpty(this.accountId);
		}
	}
	public Boolean isUserValid {
		get {
			return UUID.isNotEmpty(this.userId);
		}
	}
	public Boolean isTokenValid {
		get {
			return this.token != null
				&& this.token.isValid;
		}
	}

	@TestVisible
	private Credentials(
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final Long accountNumber,
		final String accountName,
		final String email,
		final UUID userId,
		final AccessToken token) {

		this.environment = environment;
		this.accountBaseUrl = accountBaseUrl;
		this.eSignatureBaseUrl = eSignatureBaseUrl;
		this.accountId = accountId;
		this.accountNumber = accountNumber;
		this.accountName = accountName;
		this.email = email;
		this.userId = userId;
		this.token = token;
	}

	public static Boolean isAccountValid() {
		return getInstance(UserInfo.getUserId(), false).isAccountValid;
	}

	public static Credentials getInstance() {
		return getInstance(UserInfo.getUserId(), true);
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
		if (accountCredentials != null) {
			Boolean hasUser = userCredentials != null && UUID.isNotEmpty(userCredentials.userId);
			result = new Credentials(
				accountCredentials.environment,
				accountCredentials.accountBaseUrl,
				accountCredentials.eSignatureBaseUrl,
				accountCredentials.accountId,
				accountCredentials.accountNumber,
				accountCredentials.accountName,
				accountCredentials.email,
				hasUser ? userCredentials.userId : accountCredentials.systemSenderId,
				hasUser ? userCredentials.token : null);
		} else {
			LoggerService.getInstance().error('Account and/or user configuration is null.');
			throw new DocuSignException(Label.ConfigurationError);
		}
		return result;
	}

	public static AccessToken getToken() {
		return getToken(UserInfo.getUserId());
	}

	@TestVisible
	private static AccessToken getToken(final Id userId) {
		return DB.readToken(userId);
	}

	public static Credentials save(
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final Long accountNumber,
		final String accountName,
		final String email,
		final UUID userId,
		final Boolean canManageAccount,
		final AccessToken token) {

		return save(
			UserInfo.getUserId(),
			environment,
			accountBaseUrl,
			eSignatureBaseUrl,
			accountId,
			accountNumber,
			accountName,
			email,
			userId,
			canManageAccount,
			token);
	}

	@TestVisible
	private static Credentials save(
		final Id id,
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url eSignatureBaseUrl,
		final UUID accountId,
		final Long accountNumber,
		final String accountName,
		final String email,
		final UUID userId,
		final Boolean canManageAccount,
		final AccessToken token) {

		Credentials.accountCredentials = DB.updateAccountCredentials(
			environment,
			accountBaseUrl,
			eSignatureBaseUrl,
			accountId,
			accountNumber,
			accountName,
			email);
		Credentials.UserCredentials uc = DB.updateUserCredentials(
			id,
			userId,
			canManageAccount,
			token);
		Credentials.userCredentials.put(id, uc);
		self = buildAPICredentials(Credentials.accountCredentials, uc);
		return self;
	}

	public static Credentials setToken(final Credentials.AccessToken token) {
		Credentials c = self;
		if (c == null) {
			c = getInstance();
		}
		c.token = token;
		c.isDirty = true;
		return c;
	}

	/**
	 * Saves updated user credentials (e.g. access token) to protected settings. Invoke this after all callouts are
	 * complete to avoid <code>CalloutException</code>s.
	 *
	 * @return The updated credentials.
	 */
	public static Credentials save() {
		return save(UserInfo.getUserId());
	}

	@TestVisible
	private static Credentials save(final Id userId) {
		UserCredentials uc = null;
		if (self != null) {
			uc = new UserCredentials(
				self.userId,
				false,
				self.isDirty ? DB.updateToken(userId, self.token) : self.token);
			self.isDirty = false;
		} else {
			uc = new UserCredentials(
				UUID.tryParse([SELECT Username__c FROM User WHERE Id = :userId LIMIT 1].Username__c),
				false,
				null);
		}
		Credentials.userCredentials.put(userId, uc);
		self = buildAPICredentials(getAccountCredentials(), uc);
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
						// Don't remove permission set from current user.
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
		public final DocuSign.Environment environment;
		public final Url accountBaseUrl;
		public final Url eSignatureBaseUrl;
		public final UUID accountId;
		public final Long accountNumber;
		public final String accountName;
		public final String email;
		public final UUID systemSenderId;

		public AccountCredentials(
			final DocuSign.Environment environment,
			final Url accountBaseUrl,
			final Url eSignatureBaseUrl,
			final UUID accountId,
			final Long accountNumber,
			final String accountName,
			final String email,
			final UUID systemSenderId) {

			this.environment = environment;
			this.accountBaseUrl = accountBaseUrl;
			this.eSignatureBaseUrl = eSignatureBaseUrl;
			this.accountId = accountId;
			this.accountNumber = accountNumber;
			this.accountName = accountName;
			this.email = email;
			this.systemSenderId = systemSenderId;
		}
	}

	public class AccessToken {
		public String token { get; private set; }
		public Datetime expires { get; private set; }
		public Boolean isExpired {
			get {
				return expires == null || expires < Datetime.now();
			}
		}
		public Boolean isValid {
			get {
				return String.isNotBlank(this.token) && !this.isExpired;
			}
		}

		public AccessToken(
			final String token,
			final Datetime expires) {

			this.token = token;
			this.expires = expires;
		}
	}

	public class UserCredentials {
		public UUID userId { get; private set; }
		public Boolean canManageAccount { get; private set; }
		public AccessToken token { get; private set; }

		public UserCredentials(
			final UUID userId,
			final Boolean canManageAccount,
			final AccessToken token) {

			this.userId = userId;
			this.canManageAccount = canManageAccount;
			this.token = token;
		}
	}

	@TestVisible
	private with sharing class Database {

		public AccountCredentials queryAccountCredentials() {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			if (String.isBlank(settings.Environment__c)) {
				return new AccountCredentials(DocuSign.Environment.Invalid, null, null, null, null, null, null, null);
			}

			return new AccountCredentials(
				DocuSign.parseEnvironment(settings.Environment__c),
				settings.AccountBaseUrl__c == null ? null : new Url(settings.AccountBaseUrl__c),
				settings.ESignatureBaseUrl__c == null ? null : new Url(settings.ESignatureBaseUrl__c),
				UUID.tryParse(settings.AccountId__c),
				(Long)settings.AccountNumber__c,
				settings.AccountName__c,
				settings.Email__c,
				UUID.tryParse(settings.SystemSenderId__c));
		}

		public UserCredentials queryUserCredentials(final Id userId) {
			List<User> users = [SELECT Username__c, CanManageAccount__c FROM User WHERE Id = :userId LIMIT 1];
			User u = Collection.isEmpty(users) ? null : users[0];
			return new UserCredentials(
				u == null ? null : UUID.tryParse(u.Username__c),
				u != null && u.CanManageAccount__c == true,
				u == null ? null : readToken(userId));
		}

		public AccountCredentials updateAccountCredentials(
			final DocuSign.Environment environment,
			final Url accountBaseUrl,
			final Url eSignatureBaseUrl,
			final UUID accountId,
			final Long accountNumber,
			final String accountName,
			final String email) {

			AccountSettings__c orgSettings = AccountSettings__c.getOrgDefaults();
			orgSettings.Environment__c = environment == null ? null : environment.name().toLowerCase();
			orgSettings.AccountBaseUrl__c = accountBaseUrl == null ? null : accountBaseUrl.toExternalForm();
			orgSettings.ESignatureBaseUrl__c = eSignatureBaseUrl == null ? null : eSignatureBaseUrl.toExternalForm();
			orgSettings.AccountId__c = String.valueOf(accountId);
			orgSettings.AccountNumber__c = accountNumber;
			orgSettings.AccountName__c = accountName;
			orgSettings.Email__c = email;
			orgSettings.Features__c = null;
			orgSettings.FeaturesLastChecked__c = null;
			upsert orgSettings;
			orgSettings = AccountSettings__c.getOrgDefaults();

			return new AccountCredentials(
				environment,
				accountBaseUrl,
				eSignatureBaseUrl,
				accountId,
				accountNumber,
				accountName,
				email,
				UUID.tryParse(orgSettings.SystemSenderId__c));
		}

		public UserCredentials updateUserCredentials(
			final Id id,
			final UUID userId,
			final Boolean canManageAccount,
			final AccessToken token) {

			Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
				'Username__c', 'CanManageAccount__c'
			});

			List<User> users = [SELECT Id, Username__c FROM User WHERE Id = :id LIMIT 1];
			if (Collection.isNotEmpty(users)) {
				users[0].Username__c = String.valueOf(userId);
				users[0].CanManageAccount__c = canManageAccount;
				update users[0];
			}

			return new UserCredentials(userId, canManageAccount, updateToken(id, token));
		}

		public void updateUserCredentials(final Map<Id, UserCredentials> credentials) {
			if (credentials != null && !credentials.isEmpty()) {
				Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
					'Username__c', 'CanManageAccount__c'
				});

				List<User> users = [SELECT Id, Username__c FROM User WHERE Id IN :credentials.keySet()];
				for (User u : users) {
					UserCredentials uc = credentials.get(u.Id);
					if (uc == null) {
						u.Username__c = null;
						u.CanManageAccount__c = false;
					} else {
						u.Username__c = String.valueOf(uc.userId);
						u.CanManageAccount__c = uc.canManageAccount;
					}
				}
				update users;
			}
		}

		public void deleteAccountCredentials() {
			AccountSettings__c orgSettings = AccountSettings__c.getOrgDefaults();
			orgSettings.Environment__c = null;
			orgSettings.AccountBaseUrl__c = null;
			orgSettings.ESignatureBaseUrl__c = null;
			orgSettings.AccountId__c = null;
			orgSettings.AccountNumber__c = null;
			orgSettings.AccountName__c = null;
			orgSettings.Email__c = null;
			orgSettings.SystemSenderId__c = null;
			orgSettings.Features__c = null;
			orgSettings.FeaturesLastChecked__c = null;
			upsert orgSettings;
		}

		public void deleteUserCredentials(final List<User> users) {
			if (Collection.isNotEmpty(users)) {
				Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
					'Username__c', 'CanManageAccount__c'
				});

				List<UserSettings__c> settings = new List<UserSettings__c>();
				for (User u : users) {
					u.Username__c = null;
					u.CanManageAccount__c = false;
					UserSettings__c us = UserSettings__c.getInstance(u.Id);
					if (us.Id != null) settings.add(us);
				}
				delete settings;
				update users;
			}
		}

		public AccessToken updateToken(
			final Id userId,
			final AccessToken token) {

			if (userId == null) return token;

			UserSettings__c us = UserSettings__c.getInstance(userId);
			us.AccessToken0__c = null;
			us.AccessToken1__c = null;
			us.AccessToken2__c = null;
			us.AccessToken3__c = null;
			us.AccessToken4__c = null;
			us.AccessToken5__c = null;
			us.AccessTokenExpires__c = null;

			if (token != null && token.isValid) {
				Integer len = token.token.length();
				if (len > MAX_TOKEN_LENGTH) {
					throw new DocuSignException(String.format(Label.AccessTokenTooLong_2, new List<String> {
						String.valueOf(len),
						String.valueOf(MAX_TOKEN_LENGTH)
					}));
				}
				us.AccessToken0__c = token.token.mid(0, 255);
				us.AccessToken1__c = token.token.mid(255, 255);
				us.AccessToken2__c = token.token.mid(510, 255);
				us.AccessToken3__c = token.token.mid(765, 255);
				us.AccessToken4__c = token.token.mid(1020, 255);
				us.AccessToken5__c = token.token.mid(1275, 255);
				us.AccessTokenExpires__c = token.expires;
			}

			upsert us;

			return token;
		}

		private AccessToken readToken(
			final Id userId) {

			AccessToken result = null;
			UserSettings__c us = UserSettings__c.getInstance(userId);
			if (us.AccessTokenExpires__c > Datetime.now()) {
				result = new AccessToken(
					String.join(new List<String> {
						us.AccessToken0__c, us.AccessToken1__c, us.AccessToken2__c,
						us.AccessToken3__c, us.AccessToken4__c, us.AccessToken5__c
					}, ''),
					us.AccessTokenExpires__c);
			}
			return result;
		}
	}
}
