public with sharing class Credentials {

	@TestVisible
	private static Credentials self;
	@TestVisible
	private static final Credentials.Database DB = new Credentials.Database();
	@TestVisible
	private static final Integer MAX_TOKEN_LENGTH = 1530;
	@TestVisible
	private static final Integer MAX_KEY_LENGTH = 3060;

	private Boolean isDirty = false;
	public Environment environment { get; private set; }
	public ClientCredentials client { get; private set; }
	public AccountCredentials account { get; private set; }
	public UserCredentials user { get; private set; }
	public AccessToken token { get; private set; }
	public Boolean isValid {
		get {
			return this.isAccountValid && this.isUserValid;
		}
	}
	public Boolean isAccountValid {
		get {
			return this.environment != null && this.environment.isValid
				&& this.client != null && this.client.isValid
				&& this.account != null && this.account.isValid;
		}
	}
	public Boolean isUserValid {
		get {
			return UUID.isNotEmpty(this.account.systemSenderId)
				|| (this.user != null && this.user.isValid);
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
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		this.environment = environment;
		this.client = client;
		this.account = account;
		this.user = user;
		this.token = token;
	}

	private Credentials withToken(final AccessToken token) {
		this.token = token;
		return this;
	}

	public class Environment {
		public DocuSign.Environment environment { get; private set; }
		public Url accountBaseUrl { get; private set; }
		public Url provisioningBaseUrl { get; private set; }
		public Url eSignatureBaseUrl { get; private set; }
		public Url scmAuthBaseUrl { get; private set; }
		public Url scmApiBaseUrl { get; private set; }
		public Boolean isValid {
			get {
				return this.environment != null
					&& this.environment != DocuSign.Environment.Invalid
					&& DocuSign.isValidUrl(this.accountBaseUrl)
					&& DocuSign.isValidUrl(this.provisioningBaseUrl)
					&& (this.eSignatureBaseUrl == null || DocuSign.isValidUrl(this.eSignatureBaseUrl))
					&& (this.scmAuthBaseUrl == null || DocuSign.isValidUrl(this.scmAuthBaseUrl))
					&& (this.scmApiBaseUrl == null || DocuSign.isValidUrl(this.scmApiBaseUrl));
			}
		}

		public Environment(
			final DocuSign.Environment environment,
			final Url accountBaseUrl,
			final Url provisioningBaseUrl,
			final Url eSignatureBaseUrl,
			final Url scmAuthBaseUrl,
			final Url scmApiBaseUrl) {

			this.environment = environment;
			this.accountBaseUrl = accountBaseUrl;
			this.provisioningBaseUrl = provisioningBaseUrl;
			this.eSignatureBaseUrl = eSignatureBaseUrl;
			this.scmAuthBaseUrl = scmAuthBaseUrl;
			this.scmApiBaseUrl = scmApiBaseUrl;
		}
	}

	public class ClientCredentials {
		public String id { get; private set; }
		public String secret { get; private set; }
		public Blob privateKey { get; private set; }
		public Boolean isValid {
			get {
				return String.isNotBlank(this.id)
					&& String.isNotBlank(this.secret)
					&& this.privateKey != null;
			}
		}

		public ClientCredentials(
			final String id,
			final String secret,
			final Blob privateKey) {

			this.id = id;
			this.secret = secret;
			this.privateKey = privateKey;
		}
	}

	public class AccountCredentials {
		public UUID id { get; private set; }
		public Long accountNumber { get; private set; }
		public String name { get; private set; }
		public String email { get; private set; }
		public UUID systemSenderId { get; private set; }
		public Boolean isValid {
			get {
				return UUID.isNotEmpty(this.id);
			}
		}

		public AccountCredentials(
			final UUID id,
			final Long accountNumber,
			final String name,
			final String email,
			final UUID systemSenderId) {

			this.id = id;
			this.accountNumber = accountNumber;
			this.name = name;
			this.email = email;
			this.systemSenderId = systemSenderId;
		}
	}

	public class UserCredentials {
		public UUID id { get; private set; }
		public String name { get; private set; }
		public String email { get; private set; }
		public Boolean canManageAccount { get; private set; }
		public Boolean isValid {
			get {
				return UUID.isNotEmpty(this.id);
			}
		}

		public UserCredentials(
			final UUID id,
			final String name,
			final String email,
			final Boolean canManageAccount) {

			this.id = id;
			this.name = name;
			this.email = email;
			this.canManageAccount = canManageAccount;
		}
	}

	public class AccessToken {
		public String token { get; private set; }
		public Datetime expires { get; private set; }
		public Boolean isValid {
			get {
				return String.isNotBlank(this.token)
					&& (expires == null || expires > Datetime.now());
			}
		}

		public AccessToken(
			final String token,
			final Datetime expires) {

			this.token = token;
			this.expires = expires;
		}
	}

	public class LimitedAccessToken {
		public Credentials.AccessToken token { get; private set; }
		public Url apiBaseurl { get; private set; }

		public LimitedAccessToken(
			final Credentials.AccessToken token,
			final Url apiBaseurl) {

			this.token = token;
			this.apiBaseurl = apiBaseurl;
		}
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
		} else if (UUID.isEmpty(c.account.systemSenderId) && !c.isUserValid) {
			throw UnauthorizedException.mayRequireActivation();
		}
	}

	@TestVisible
	private static Credentials getInstance(final Id userId, final Boolean validate) {
		Credentials result = null;
		if (userId == UserInfo.getUserId()) { // 99% case user needs stored DS creds for API calls\
			if (self == null) {
				result = DB.queryCredentials(userId);
				if (validate) validate(result);
				self = result;
			}
			result = self;
		} else {
			result = DB.queryCredentials(userId);
			if (validate) validate(result);
		}
		return result;
	}

	public static AccessToken getToken() {
		return DB.queryToken(UserInfo.getUserId());
	}

	@TestVisible
	private with sharing class Database {

		private Environment getEnvironment(final AccountSettings__c settings) {
			if (settings == null || String.isBlank(settings.Environment__c)) {
				return new Environment(DocuSign.Environment.Invalid, null, null, null, null, null);
			}
			return new Environment(
				DocuSign.parseEnvironment(settings.Environment__c),
				settings.AccountBaseUrl__c == null ? null : new Url(settings.AccountBaseUrl__c),
				settings.ProvisioningBaseUrl__c == null ? null : new Url(settings.ProvisioningBaseUrl__c),
				settings.ESignatureBaseUrl__c == null ? null : new Url(settings.ESignatureBaseUrl__c),
				settings.ScmAuthBaseUrl__c == null ? null : new Url(settings.ScmAuthBaseUrl__c),
				settings.ScmApiBaseUrl__c == null ? null : new Url(settings.ScmApiBaseUrl__c));
		}

		private ClientCredentials getClient(final AccountSettings__c settings) {
			if (settings == null) return new ClientCredentials(null, null, null);

			return new ClientCredentials(
				settings.ClientId__c,
				settings.ClientSecret__c,
				EncodingUtil.base64Decode(String.join(new List<String> {
					settings.PrivateKey0__c, settings.PrivateKey1__c, settings.PrivateKey2__c, settings.PrivateKey3__c,
					settings.PrivateKey4__c, settings.PrivateKey5__c, settings.PrivateKey6__c, settings.PrivateKey7__c,
					settings.PrivateKey8__c, settings.PrivateKey9__c, settings.PrivateKey10__c, settings.PrivateKey11__c
				}, '')));
		}

		private AccountCredentials getAccount(final AccountSettings__c settings) {
			if (settings == null) return new AccountCredentials(null, null, null, null, null);

			return new AccountCredentials(
				UUID.tryParse(settings.AccountId__c),
				(Long)settings.AccountNumber__c,
				settings.AccountName__c,
				settings.Email__c,
				UUID.tryParse(settings.SystemSenderId__c));
		}

		@TestVisible
		private AccessToken getToken(final UserSettings__c settings) {
			if (settings != null && settings.AccessTokenExpires__c > Datetime.now()) {
				return new AccessToken(
					String.join(new List<String> {
						settings.AccessToken0__c, settings.AccessToken1__c, settings.AccessToken2__c,
						settings.AccessToken3__c, settings.AccessToken4__c, settings.AccessToken5__c
					}, ''),
					settings.AccessTokenExpires__c);
			}
			return new AccessToken(null, null);
		}

		private UserCredentials queryUser(final Id userId, final UUID systemSenderId) {
			Permissions.verifyIsQueryable(Schema.User.getSObjectType(), new List<String> {
				'Name', 'Email',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'InviteDate__c',
				Application.namespacePrefix + 'Status__c'
			});

			if (userId == null) return new UserCredentials(null, null, null, false);

			User user = (User)Collection.head([
				SELECT Username__c, Name, Email, CanManageAccount__c, InviteId__c, InviteDate__c, Status__c
				FROM User
				WHERE Id = :userId
				LIMIT 1
			]);

			return new UserCredentials(
				String.isBlank(user.Username__c) ? systemSenderId : UUID.tryParse(user.Username__c),
				user.Name,
				user.Email,
				user.CanManageAccount__c == true);
		}

		public Credentials queryCredentials(final Id userId) {
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			return new Credentials(
				getEnvironment(accountSettings),
				getClient(accountSettings),
				getAccount(accountSettings),
				queryUser(userId, UUID.tryParse(accountSettings.SystemSenderId__c)),
				queryToken(userId));
		}

		public AccessToken queryToken(final Id userId) {
			return getToken(UserSettings__c.getInstance(userId));
		}

		private AccountSettings__c setEnvironment(
			final AccountSettings__c settings,
			final Environment environment) {

			if (settings == null || environment == null || !environment.isValid) return settings;

			settings.Environment__c = environment.environment == null
				? null : environment.environment.name();
			settings.AccountBaseUrl__c = environment.accountBaseUrl == null
				? null : environment.accountBaseUrl.toExternalForm();
			settings.ProvisioningBaseUrl__c = environment.provisioningBaseUrl == null
				? null : environment.provisioningBaseUrl.toExternalForm();
			settings.ESignatureBaseUrl__c = environment.eSignatureBaseUrl == null
				? null : environment.eSignatureBaseUrl.toExternalForm();
			settings.ScmAuthBaseUrl__c = environment.scmAuthBaseUrl == null
				? null : environment.scmAuthBaseUrl.toExternalForm();
			settings.ScmApiBaseUrl__c = environment.scmApiBaseUrl == null
				? null : environment.scmApiBaseUrl.toExternalForm();
			return settings;
		}

		private AccountSettings__c setClient(
			final AccountSettings__c settings,
			final ClientCredentials client) {

			if (settings == null || client == null || !client.isValid) return settings;

			String pvk = EncodingUtil.base64Encode(client.privateKey);
			Integer len = pvk.length();
			if (len > MAX_KEY_LENGTH) {
				throw new DocuSignException(String.format(Label.KeyTooLong_2, new List<String> {
					String.valueOf(len),
					String.valueOf(MAX_KEY_LENGTH)
				}));
			}
			settings.ClientId__c = client.id;
			settings.ClientSecret__c = client.secret;
			settings.PrivateKey0__c = pvk.mid(0, 255);
			settings.PrivateKey1__c = pvk.mid(255, 255);
			settings.PrivateKey2__c = pvk.mid(510, 255);
			settings.PrivateKey3__c = pvk.mid(765, 255);
			settings.PrivateKey4__c = pvk.mid(1020, 255);
			settings.PrivateKey5__c = pvk.mid(1275, 255);
			settings.PrivateKey6__c = pvk.mid(1530, 255);
			settings.PrivateKey7__c = pvk.mid(1785, 255);
			settings.PrivateKey8__c = pvk.mid(2040, 255);
			settings.PrivateKey9__c = pvk.mid(2295, 255);
			settings.PrivateKey10__c = pvk.mid(2550, 255);
			settings.PrivateKey11__c = pvk.mid(2805, 255);
			return settings;
		}

		private AccountSettings__c setAccount(
			final AccountSettings__c settings,
			final AccountCredentials account) {

			if (settings == null || account == null || !account.isValid) return settings;

			settings.AccountId__c = String.valueOf(account.id);
			settings.AccountNumber__c = account.accountNumber;
			settings.AccountName__c = account.name;
			settings.Email__c = account.email;
			settings.SystemSenderId__c = String.valueOf(account.systemSenderId);
			return settings;
		}

		private UserCredentials updateUser(
			final Id userId,
			final UserCredentials user) {

			Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'InviteDate__c',
				Application.namespacePrefix + 'Status__c'
			});

			if (userId == null || user == null) return user;

			if (userId != null && user != null) {
				update new User(
					Id = userId,
					Username__c = String.valueOf(user.id),
					CanManageAccount__c = user.canManageAccount == true);
			}

			return user;
		}

		public UserSettings__c clearToken(final UserSettings__c settings) {
			if (settings == null) return null;

			settings.AccessToken0__c = null;
			settings.AccessToken1__c = null;
			settings.AccessToken2__c = null;
			settings.AccessToken3__c = null;
			settings.AccessToken4__c = null;
			settings.AccessToken5__c = null;
			settings.AccessTokenExpires__c = null;

			return settings;
		}

		public Credentials updateCredentials(
			final Id userId,
			final Environment environment,
			final ClientCredentials client,
			final AccountCredentials account,
			final UserCredentials user,
			final AccessToken token) {

			AccountSettings__c accountSettings = setEnvironment(AccountSettings__c.getOrgDefaults(), environment);
			accountSettings = setClient(accountSettings, client);
			accountSettings = setAccount(accountSettings, account);
			upsert accountSettings;

			updateUser(userId, user);
			updateToken(userId, token);

			return this.queryCredentials(userId);
		}

		public AccessToken updateToken(
			final Id userId,
			final AccessToken token) {

			if (userId == null) return token;

			UserSettings__c settings = clearToken(UserSettings__c.getInstance(userId));

			if (token != null && token.isValid) {
				Integer len = token.token.length();
				if (len > MAX_TOKEN_LENGTH) {
					throw new DocuSignException(String.format(Label.AccessTokenTooLong_2, new List<String> {
						String.valueOf(len),
						String.valueOf(MAX_TOKEN_LENGTH)
					}));
				}
				settings.AccessToken0__c = token.token.mid(0, 255);
				settings.AccessToken1__c = token.token.mid(255, 255);
				settings.AccessToken2__c = token.token.mid(510, 255);
				settings.AccessToken3__c = token.token.mid(765, 255);
				settings.AccessToken4__c = token.token.mid(1020, 255);
				settings.AccessToken5__c = token.token.mid(1275, 255);
				settings.AccessTokenExpires__c = token.expires;
			}

			upsert settings;

			return token;
		}

		public Map<Id, UserCredentials> updateUsers(final Map<Id, UserCredentials> users) {
			if (users == null || users.isEmpty()) return users;

			Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'InviteDate__c',
				Application.namespacePrefix + 'Status__c'
			});

			List<User> dbUsers = [
				SELECT Id, Username__c, CanManageAccount__c, InviteId__c, InviteDate__c, Status__c
				FROM User
				WHERE Id IN :users.keySet()
			];
			for (User u : dbUsers) {
				UserCredentials uu = users.get(u.Id);
				if (uu == null) {
					u.Username__c = null;
					u.CanManageAccount__c = false;
					u.InviteId__c = null;
					u.InviteDate__c = null;
					u.Status__c = null;
				} else {
					u.Username__c = String.valueOf(uu.id);
					u.CanManageAccount__c = uu.canManageAccount == true;
					// TODO: Update invite properties
				}
			}
			update dbUsers;

			return users;
		}

		private void deleteConfigurations(final Set<String> names) {
			Permissions.verifyIsDeletable(Configuration__c.getSObjectType());

			delete [
				SELECT Id
				FROM Configuration__c
				WHERE Name IN :names
				LIMIT 2000
			];
		}

		public AccountSettings__c deleteAccountCredentials() {
			deleteConfigurations(new Set<String> { 'Gen' });

			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.Environment__c = null;
			settings.ClientId__c = null;
			settings.ClientSecret__c = null;
			settings.PrivateKey0__c = null;
			settings.PrivateKey1__c = null;
			settings.PrivateKey2__c = null;
			settings.PrivateKey3__c = null;
			settings.PrivateKey4__c = null;
			settings.PrivateKey5__c = null;
			settings.PrivateKey6__c = null;
			settings.PrivateKey7__c = null;
			settings.PrivateKey8__c = null;
			settings.PrivateKey9__c = null;
			settings.PrivateKey10__c = null;
			settings.PrivateKey11__c = null;
			settings.AccountBaseUrl__c = null;
			settings.ProvisioningBaseUrl__c = null;
			settings.ESignatureBaseUrl__c = null;
			settings.ScmAuthBaseUrl__c = null;
			settings.ScmApiBaseUrl__c = null;
			settings.InviteCallbackUrl__c = null;
			settings.InviteRedirectUrl__c = null;
			settings.AccountId__c = null;
			settings.AccountNumber__c = null;
			settings.AccountName__c = null;
			settings.Email__c = null;
			settings.SystemSenderId__c = null;
			settings.Features__c = null;
			settings.FeaturesLastChecked__c = null;
			settings.AdministratorProfileId__c = null;
			settings.SenderProfileId__c = null;
			upsert settings;
			return settings;
		}

		public List<Schema.User> deleteUserCredentials(final List<Schema.User> users) {
			if (Collection.isNotEmpty(users)) {
				Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
					Application.namespacePrefix + 'Username__c',
					Application.namespacePrefix + 'CanManageAccount__c',
					Application.namespacePrefix + 'InviteDate__c',
					Application.namespacePrefix + 'InviteId__c',
					Application.namespacePrefix + 'Status__c'
				});

				List<UserSettings__c> settings = new List<UserSettings__c>();
				for (Schema.User u : users) {
					u.Username__c = null;
					u.CanManageAccount__c = false;
					u.InviteDate__c = null;
					u.InviteId__c = null;
					u.Status__c = null;
					UserSettings__c us = UserSettings__c.getInstance(u.Id);
					if (us.Id != null) settings.add(us);
				}
				delete settings;
				update users;
			}
			return users;
		}
	}

	public static Credentials save(
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		return save(
			UserInfo.getUserId(),
			environment,
			client,
			account,
			user,
			token);
	}

	@TestVisible
	private static Credentials save(
		final Id userId,
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		self = DB.updateCredentials(
			userId,
			environment,
			client,
			account,
			user,
			token);
		return self;
	}

	public static Credentials setToken(final Credentials.AccessToken token) {
		Credentials result = getInstance(UserInfo.getUserId(), false).withToken(token);
		result.isDirty = true;
		return result;
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
		if (self != null && self.isDirty) {
			self = self.withToken(DB.updateToken(userId, self.token));
			self.isDirty = false;
		}
		return getInstance(userId, false);
	}

	public static Map<Id, UserCredentials> addUsers(final Map<Id, UserCredentials> users) {
		Set<Id> adminIds = new Set<Id>();
		Set<Id> userIds = new Set<Id>();
		for (Id userId : users.keySet()) {
			UserCredentials u = users.get(userId);
			if (u != null) {
				if (u.canManageAccount) {
					adminIds.add(userId);
				} else {
					userIds.add(userId);
				}
			}
		}

		Map<Id, UserCredentials> result = DB.updateUsers(users);
		if (!userIds.isEmpty()) {
			assignUserPermissionSet(userIds);
		}
		if (!adminIds.isEmpty()) {
			assignAdminPermissionSet(adminIds);
		}
		return result;
	}

	public static void clear(final Boolean resetUsers) {
		DB.deleteAccountCredentials();
		if (resetUsers) {
			Set<Id> userIds = new Set<Id>();
			Boolean isWorking = true;
			while (isWorking) {
				List<Schema.User> users = [
					SELECT Id, Username__c, CanManageAccount__c, InviteId__c, InviteDate__c, Status__c
					FROM User
					WHERE Username__c != NULL
					LIMIT 200
				];
				if (Collection.isNotEmpty(users)) {
					DB.deleteUserCredentials(users);
					for (Schema.User u : users) {
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
		DB.deleteUserCredentials([
			SELECT Id, Username__c, CanManageAccount__c, InviteId__c, InviteDate__c, Status__c
			FROM User
			WHERE Id IN :userIds
		]);
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
}
